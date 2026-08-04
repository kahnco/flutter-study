import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/get_todos.dart';
import 'package:flutter_study/features/todos/domain/usecases/remove_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/toggle_todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
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
/// 검색은 매 글자마다 질의하지 않도록 [searchDebounce] 만큼 **디바운스**한다 —
/// 2편에서 미뤄 둔 '이벤트 트랜스포머'를 여기서 직접 짠다.
@injectable
class TodosBloc {
  TodosBloc(this._getTodos, this._addTodo, this._toggleTodo, this._removeTodo) {
    _drain();
  }

  final GetTodos _getTodos;
  final AddTodo _addTodo;
  final ToggleTodo _toggleTodo;
  final RemoveTodo _removeTodo;

  /// 검색 입력이 멈춘 뒤 질의까지의 대기 시간. 테스트는 0 으로 줄여 쓴다.
  /// (생성자 파라미터로 두면 injectable 이 Duration 을 주입하려 하므로 필드로 둔다.)
  Duration searchDebounce = const Duration(milliseconds: 300);

  final StreamController<TodosEvent> _events = StreamController<TodosEvent>();
  final StreamController<TodosState> _states =
      StreamController<TodosState>.broadcast();

  // 지금 화면이 걸어 둔 조회 조건. 재적재·재질의는 이 값으로 한다.
  TodosFilter _filter = TodosFilter.all;
  String _query = '';
  Timer? _debounce;

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
        await _runQuery();
      case TodoAdded(:final rawTitle):
        await _onAdded(rawTitle);
      case TodoToggled(:final id):
        await _mutate(await _toggleTodo(id));
      case TodoRemoved(:final id):
        await _mutate(await _removeTodo(id));
      case FilterChanged(:final filter):
        // 탭은 타이핑이 아니니 디바운스 없이 즉시 재질의한다.
        _filter = filter;
        await _runQuery();
      case SearchChanged(:final query):
        // 타이핑은 멈출 때까지 기다렸다가 한 번만 질의한다(디바운스).
        _query = query;
        _debounce?.cancel();
        _debounce = Timer(searchDebounce, () => add(const QueryRefreshed()));
      case QueryRefreshed():
        await _runQuery();
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

  /// 변경 유스케이스의 결과를 공통 처리: 실패는 한 줄 오류, 성공은 목록 재질의.
  Future<void> _mutate(Either<Failure, Object?> result) => result.match(
        (failure) async => _showError(failure.message),
        (_) async => _runQuery(),
      );

  /// 지금 조건(_filter·_query)으로 저장소에 질의해 결과를 방출한다.
  /// 필터·검색이 SQL 로 내려가 있으니, 돌아온 목록이 곧 화면에 그릴 목록이다.
  Future<void> _runQuery() async {
    final result = await _getTodos(TodoQuery(status: _filter, text: _query));
    result.match(
      (failure) => _emit(TodosFailure(failure.message)),
      (todos) => _emit(TodosLoaded(todos, filter: _filter, query: _query)),
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

  /// StreamController 와 디바운스 타이머는 직접 닫아야 한다 — 화면이 사라질 때.
  Future<void> dispose() async {
    _debounce?.cancel();
    await _events.close();
    await _states.close();
  }
}
