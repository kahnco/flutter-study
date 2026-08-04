import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/usecase/usecase.dart';
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/get_todos.dart';
import 'package:flutter_study/features/todos/domain/usecases/remove_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/toggle_todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_filter.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_state.dart';

/// BLoC 패턴을 패키지 없이 직접 구현한다.
///
/// 본질은 세 가지뿐이다.
///   1. 이벤트가 [add] 로 **들어온다**(sink).
///   2. 그 사이에서 유스케이스를 부르는 **UI 없는 로직**이 돈다.
///   3. 상태가 [stream] 으로 **나간다**.
///
/// 이벤트는 [_events] 를 `await for` 로 **하나씩 순서대로** 처리한다 —
/// flutter_bloc 의 기본 순차 트랜스포머가 하던 일을 눈에 보이게 짠 것이다.
@injectable
class TodosBloc {
  TodosBloc(this._getTodos, this._addTodo, this._toggleTodo, this._removeTodo) {
    _drain();
  }

  final GetTodos _getTodos;
  final AddTodo _addTodo;
  final ToggleTodo _toggleTodo;
  final RemoveTodo _removeTodo;

  final StreamController<TodosEvent> _events = StreamController<TodosEvent>();
  final StreamController<TodosState> _states =
      StreamController<TodosState>.broadcast();

  TodosState _current = const TodosInitial();

  /// 화면이 구독하는 상태 흐름.
  Stream<TodosState> get stream => _states.stream;

  /// 늦게 붙는 구독자(StreamBuilder)가 첫 프레임에 쓸 현재 상태.
  TodosState get state => _current;

  /// 화면이 던지는 유일한 입구.
  void add(TodosEvent event) => _events.add(event);

  void _emit(TodosState next) {
    _current = next;
    _states.add(next);
  }

  /// 이벤트 큐를 순서대로 비운다. 스트림이 닫히면 루프도 끝난다.
  Future<void> _drain() async {
    await for (final event in _events.stream) {
      await _handle(event);
    }
  }

  Future<void> _handle(TodosEvent event) async {
    switch (event) {
      case TodosStarted():
        _emit(const TodosLoading());
        await _reload();
      case TodoAdded(:final rawTitle):
        await _onAdded(rawTitle);
      case TodoToggled(:final id):
        await _mutate(await _toggleTodo(id));
      case TodoRemoved(:final id):
        await _mutate(await _removeTodo(id));
      case FilterChanged(:final filter):
        // 저장소를 건드리지 않는 화면 상태 변경 — 현재 목록에 필터만 갈아 끼운다.
        final now = _current;
        if (now is TodosLoaded) {
          _emit(TodosLoaded(now.todos, filter: filter, query: now.query));
        }
      case SearchChanged(:final query):
        final now = _current;
        if (now is TodosLoaded) {
          _emit(TodosLoaded(now.todos, filter: now.filter, query: query));
        }
    }
  }

  Future<void> _onAdded(String rawTitle) async {
    // 날것의 문자열이 값 객체를 거치는 지점 — 규칙 위반은 여기서 걸린다.
    final title = TodoTitle.create(rawTitle);
    await title.match(
      (failure) async => _showError(failure.message),
      (value) async => _mutate(await _addTodo(value)),
    );
  }

  /// 변경 유스케이스의 결과를 공통 처리: 실패는 한 줄 오류, 성공은 목록 재적재.
  Future<void> _mutate(Either<Failure, Object?> result) => result.match(
        (failure) async => _showError(failure.message),
        (_) async => _reload(),
      );

  /// 목록을 다시 읽어 성공/실패 상태로 방출한다(단일 진실원천).
  /// 재적재 뒤에도 현재 필터·검색어는 이어 간다(추가/토글이 뷰를 리셋하지 않게).
  Future<void> _reload() async {
    final now = _current;
    final filter = now is TodosLoaded ? now.filter : TodosFilter.all;
    final query = now is TodosLoaded ? now.query : '';
    final result = await _getTodos(const NoParams());
    result.match(
      (failure) => _emit(TodosFailure(failure.message)),
      (todos) => _emit(TodosLoaded(todos, filter: filter, query: query)),
    );
  }

  /// 목록·필터·검색어는 유지하고 화면에 한 줄짜리 오류만 얹는다.
  void _showError(String message) {
    final now = _current;
    _emit(now is TodosLoaded
        ? TodosLoaded(now.todos,
            filter: now.filter, query: now.query, error: message)
        : TodosFailure(message));
  }

  /// StreamController 는 직접 닫아야 한다 — 화면이 사라질 때 호출한다.
  Future<void> dispose() async {
    await _events.close();
    await _states.close();
  }
}
