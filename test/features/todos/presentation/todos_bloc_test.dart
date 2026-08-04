import 'package:flutter_study/core/clock/clock.dart';
import 'package:flutter_study/core/id/id_generator.dart';
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/get_todos.dart';
import 'package:flutter_study/features/todos/domain/usecases/remove_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/toggle_todo.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_filter.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TodosBloc bloc;

  setUp(() {
    final local = InMemoryTodoLocalDataSource();
    final repo =
        TodosRepositoryImpl(local, SequentialIdGenerator(), FixedClock());
    bloc = TodosBloc(
      GetTodos(repo),
      AddTodo(repo),
      ToggleTodo(repo),
      RemoveTodo(repo),
    );
  });

  tearDown(() => bloc.dispose());

  test('시작하면 로딩을 거쳐 빈 목록으로 간다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>().having((s) => s.todos, 'todos', isEmpty),
      ]),
    );
    bloc.add(const TodosStarted());
  });

  test('제목을 넣으면 목록에 한 건이 쌓인다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>().having((s) => s.todos, 'todos', isEmpty),
        isA<TodosLoaded>()
            .having((s) => s.todos.length, 'length', 1)
            .having((s) => s.todos.first.title.value, 'title', '우유 사기'),
      ]),
    );
    bloc
      ..add(const TodosStarted())
      ..add(const TodoAdded('우유 사기'));
  });

  test('빈 제목은 저장되지 않고 화면에 오류 한 줄만 실린다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>().having((s) => s.todos, 'todos', isEmpty),
        isA<TodosLoaded>()
            .having((s) => s.todos, 'todos', isEmpty)
            .having((s) => s.error, 'error', '할 일을 입력하세요'),
      ]),
    );
    bloc
      ..add(const TodosStarted())
      ..add(const TodoAdded('   '));
  });

  test('토글하면 완료 상태가 뒤집힌다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>().having((s) => s.todos, 'todos', isEmpty),
        isA<TodosLoaded>().having((s) => s.todos.length, 'length', 1),
        isA<TodosLoaded>()
            .having((s) => s.todos.single.completed, 'completed', isTrue),
      ]),
    );
    // FixedClock/SequentialIdGenerator 라 추가되는 항목의 id 는 'id-1' 로 결정적.
    bloc
      ..add(const TodosStarted())
      ..add(const TodoAdded('청소'))
      ..add(const TodoToggled('id-1'));
  });

  test('삭제하면 목록에서 빠진다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>().having((s) => s.todos, 'todos', isEmpty),
        isA<TodosLoaded>().having((s) => s.todos.length, 'length', 1),
        isA<TodosLoaded>().having((s) => s.todos, 'todos', isEmpty),
      ]),
    );
    bloc
      ..add(const TodosStarted())
      ..add(const TodoAdded('버릴 것'))
      ..add(const TodoRemoved('id-1'));
  });

  test('필터를 바꾸면 저장소는 그대로고 보이는 목록만 좁아진다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>(),
        isA<TodosLoaded>().having((s) => s.todos.length, 'length', 1), // 추가
        isA<TodosLoaded>().having((s) => s.todos.single.completed, 'done', true),
        // 미완료 필터: 전체 목록(todos)은 1건 그대로, 보이는 건 0건
        isA<TodosLoaded>()
            .having((s) => s.todos.length, 'todos', 1)
            .having((s) => s.visibleTodos, 'visible', isEmpty),
      ]),
    );
    bloc
      ..add(const TodosStarted())
      ..add(const TodoAdded('청소'))
      ..add(const TodoToggled('id-1')) // 완료로
      ..add(const FilterChanged(TodosFilter.active)); // 미완료만 → 안 보임
  });

  test('검색어를 바꾸면 매칭되는 것만 보인다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>(),
        isA<TodosLoaded>().having((s) => s.todos.length, 'length', 1),
        isA<TodosLoaded>().having((s) => s.todos.length, 'length', 2),
        isA<TodosLoaded>()
            .having((s) => s.query, 'query', '우유')
            .having((s) => s.visibleTodos.map((t) => t.title.value).toList(),
                'visible', ['우유 사기']),
      ]),
    );
    bloc
      ..add(const TodosStarted())
      ..add(const TodoAdded('우유 사기'))
      ..add(const TodoAdded('청소하기'))
      ..add(const SearchChanged('우유'));
  });

  test('추가해도 현재 필터·검색어는 유지된다', () {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<TodosLoading>(),
        isA<TodosLoaded>(),
        // 검색어 설정(빈 목록)
        isA<TodosLoaded>().having((s) => s.query, 'query', '청소'),
        // 추가 후에도 query 가 남아 있어야 한다
        isA<TodosLoaded>()
            .having((s) => s.query, 'query', '청소')
            .having((s) => s.todos.length, 'length', 1),
      ]),
    );
    bloc
      ..add(const TodosStarted())
      ..add(const SearchChanged('청소'))
      ..add(const TodoAdded('청소하기'));
  });
}
