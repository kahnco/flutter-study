import 'package:flutter_study/core/clock/clock.dart';
import 'package:flutter_study/core/id/id_generator.dart';
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/get_todos.dart';
import 'package:flutter_study/features/todos/domain/usecases/remove_todo.dart';
import 'package:flutter_study/features/todos/domain/usecases/toggle_todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';
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
    )..searchDebounce = Duration.zero; // 테스트에선 디바운스를 즉시로
  });

  tearDown(() => bloc.dispose());

  // 디바운스(타이머)가 끼면 emitsInOrder 는 순서가 흔들린다. 그래서 원하는
  // 상태가 나올 때까지 기다리는 헬퍼로, 단계마다 확정한 뒤 다음을 던진다.
  Future<TodosLoaded> nextLoaded(bool Function(TodosLoaded) predicate) => bloc
      .stream
      .where((s) => s is TodosLoaded && predicate(s))
      .cast<TodosLoaded>()
      .first;

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

  test('필터를 바꾸면 SQL 조회로 완료/미완료만 돌아온다', () async {
    final started = nextLoaded((s) => s.todos.isEmpty);
    bloc.add(const TodosStarted());
    await started;

    final added = nextLoaded((s) => s.todos.length == 1);
    bloc.add(const TodoAdded('청소'));
    await added;

    final toggled = nextLoaded((s) => s.todos.single.completed);
    bloc.add(const TodoToggled('id-1'));
    await toggled;

    // 미완료 필터 → 완료된 항목은 조회 결과에서 빠진다.
    final filtered = nextLoaded((s) => s.filter == TodosFilter.active);
    bloc.add(const FilterChanged(TodosFilter.active));
    expect((await filtered).todos, isEmpty);
  });

  test('검색어를 디바운스 뒤 SQL LIKE 로 걸러 온다', () async {
    final started = nextLoaded((s) => s.todos.isEmpty);
    bloc.add(const TodosStarted());
    await started;

    final two = nextLoaded((s) => s.todos.length == 2);
    bloc
      ..add(const TodoAdded('우유 사기'))
      ..add(const TodoAdded('청소하기'));
    await two;

    final searched = nextLoaded((s) => s.query == '우유');
    bloc.add(const SearchChanged('우유'));
    final result = await searched;
    expect(result.todos.map((t) => t.title.value).toList(), ['우유 사기']);
  });

  test('검색 중 추가해도 검색어가 유지되고 결과가 갱신된다', () async {
    final started = nextLoaded((s) => s.todos.isEmpty);
    bloc.add(const TodosStarted());
    await started;

    final searched = nextLoaded((s) => s.query == '청소');
    bloc.add(const SearchChanged('청소'));
    await searched; // 아직 항목 없음 → 빈 결과, query 는 '청소'

    final afterAdd = nextLoaded((s) => s.query == '청소' && s.todos.length == 1);
    bloc.add(const TodoAdded('청소하기'));
    expect((await afterAdd).todos.single.title.value, '청소하기');
  });
}
