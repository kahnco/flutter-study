import 'package:injectable/injectable.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// 로컬 저장소 계약. 행 단위 CRUD + 조건 조회([search]).
/// 이 인터페이스는 data 계층 것이라, 여기를 바꿔도 도메인은 그대로다.
/// 실패는 예외를 **던진다**(repository 가 잡아 Either 로 바꾼다).
abstract interface class TodoLocalDataSource {
  Future<List<TodoModel>> readAll();
  Future<List<TodoModel>> search(TodoQuery query);
  Future<void> insert(TodoModel todo);
  Future<void> update(TodoModel todo);
  Future<void> delete(String id);
}

/// 인메모리 구현. 테스트·데모(fake)용 — 프로세스가 살아있는 동안만 유지된다.
/// 목록은 **삽입 순서**로 돌려주어, SQL 의 `ORDER BY created_at, rowid` 와 맞춘다.
/// [search] 의 필터·검색 의미도 sqflite 구현과 같게 맞춘다(대소문자 무시 contains).
@LazySingleton(as: TodoLocalDataSource, env: ['fake'])
class InMemoryTodoLocalDataSource implements TodoLocalDataSource {
  final List<TodoModel> _store = [];

  @override
  Future<List<TodoModel>> readAll() async => List.unmodifiable(_store);

  @override
  Future<List<TodoModel>> search(TodoQuery query) async {
    final needle = query.text.trim().toLowerCase();
    final matched = _store.where((m) {
      final matchesStatus = switch (query.status) {
        TodosFilter.all => true,
        TodosFilter.active => !m.completed,
        TodosFilter.completed => m.completed,
      };
      final matchesText =
          needle.isEmpty || m.title.toLowerCase().contains(needle);
      return matchesStatus && matchesText;
    });
    // SQL 의 LIMIT/OFFSET 과 같은 의미로 창을 자른다.
    final paged =
        query.limit == null ? matched : matched.skip(query.offset).take(query.limit!);
    return paged.toList();
  }

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
