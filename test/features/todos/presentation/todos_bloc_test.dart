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
}
