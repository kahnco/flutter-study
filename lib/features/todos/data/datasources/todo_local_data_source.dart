import 'package:injectable/injectable.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';

/// 로컬 저장소 계약. 이제 통째로 덮는 writeAll 이 아니라 **행 단위**로 다룬다 —
/// SQL 의 INSERT/UPDATE/DELETE 를 그대로 담기 위해서다. 이 인터페이스는 data 계층
/// 것이라, 여기를 바꿔도 도메인(엔티티·유스케이스·repository 계약)은 그대로다.
/// 실패는 예외를 **던진다**(repository 가 잡아 Either 로 바꾼다).
abstract interface class TodoLocalDataSource {
  Future<List<TodoModel>> readAll();
  Future<void> insert(TodoModel todo);
  Future<void> update(TodoModel todo);
  Future<void> delete(String id);
}

/// 인메모리 구현. 테스트·데모(fake)용 — 프로세스가 살아있는 동안만 유지된다.
/// 목록은 **삽입 순서**로 돌려주어, SQL 의 `ORDER BY created_at, rowid` 와 맞춘다.
@LazySingleton(as: TodoLocalDataSource, env: ['fake'])
class InMemoryTodoLocalDataSource implements TodoLocalDataSource {
  final List<TodoModel> _store = [];

  @override
  Future<List<TodoModel>> readAll() async => List.unmodifiable(_store);

  @override
  Future<void> insert(TodoModel todo) async => _store.add(todo);

  @override
  Future<void> update(TodoModel todo) async {
    final index = _store.indexWhere((m) => m.id == todo.id);
    if (index >= 0) _store[index] = todo;
  }

  @override
  Future<void> delete(String id) async =>
      _store.removeWhere((m) => m.id == id);
}
