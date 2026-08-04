import 'package:flutter_study/core/clock/clock.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/id/id_generator.dart';
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';
import 'package:flutter_study/features/todos/data/repositories/todos_repository_impl.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

/// 항상 예외를 던지는 datasource — 경계에서 Failure 로 접히는지 본다.
class _ThrowingDataSource implements TodoLocalDataSource {
  @override
  Future<List<TodoModel>> readAll() async => throw Exception('disk');
  @override
  Future<List<TodoModel>> search(TodoQuery query) async =>
      throw Exception('disk');
  @override
  Future<void> insert(TodoModel todo) async => throw Exception('disk');
  @override
  Future<void> update(TodoModel todo) async => throw Exception('disk');
  @override
  Future<void> delete(String id) async => throw Exception('disk');
}

void main() {
  late InMemoryTodoLocalDataSource local;
  late TodosRepositoryImpl repo;

  setUp(() {
    local = InMemoryTodoLocalDataSource();
    repo = TodosRepositoryImpl(local, SequentialIdGenerator(), FixedClock());
  });

  test('add → getAll: 주입된 clock/id 로 결정적으로 저장된다', () async {
    final added = await repo.add(TodoTitle.trusted('첫 할 일'));
    final todo = added.getOrElse((_) => throw StateError('right'));
    expect(todo.id, 'id-1');
    expect(todo.completed, isFalse);
    expect(todo.createdAt, DateTime.fromMillisecondsSinceEpoch(0));

    final all = await repo.search(const TodoQuery());
    expect(all.getOrElse((_) => []).length, 1);
  });

  test('toggle 은 완료 상태를 뒤집는다', () async {
    final todo = (await repo.add(TodoTitle.trusted('x')))
        .getOrElse((_) => throw StateError('right'));
    await repo.toggle(todo.id);
    final all = (await repo.search(const TodoQuery())).getOrElse((_) => []);
    expect(all.single.completed, isTrue);
  });

  test('remove 는 해당 항목만 지운다', () async {
    final a = (await repo.add(TodoTitle.trusted('a')))
        .getOrElse((_) => throw StateError('right'));
    await repo.add(TodoTitle.trusted('b'));
    await repo.remove(a.id);
    final all = (await repo.search(const TodoQuery())).getOrElse((_) => []);
    expect(all.length, 1);
    expect(all.single.title.value, 'b');
  });

  test('datasource 예외는 CacheFailure 로 접힌다(예외 누출 없음)', () async {
    final throwing =
        TodosRepositoryImpl(_ThrowingDataSource(), SequentialIdGenerator(), FixedClock());
    final result = await throwing.search(const TodoQuery());
    expect(result.isLeft(), isTrue);
    result.match(
      (f) => expect(f, isA<CacheFailure>()),
      (_) => fail('실패여야'),
    );
  });
}
