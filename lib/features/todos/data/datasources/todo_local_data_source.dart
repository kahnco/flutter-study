import 'package:injectable/injectable.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';

/// 로컬 저장소 계약. 실패는 예외를 **던진다**(repository 가 잡아 Either 로 바꾼다).
abstract interface class TodoLocalDataSource {
  Future<List<TodoModel>> readAll();
  Future<void> writeAll(List<TodoModel> todos);
}

/// 인메모리 구현. 테스트·데모(fake)용 — 프로세스가 살아있는 동안만 유지된다.
/// 실제 영속(prod) 어댑터는 다음 편에서 붙인다.
@LazySingleton(as: TodoLocalDataSource, env: ['fake'])
class InMemoryTodoLocalDataSource implements TodoLocalDataSource {
  final List<TodoModel> _store = [];

  @override
  Future<List<TodoModel>> readAll() async => List.unmodifiable(_store);

  @override
  Future<void> writeAll(List<TodoModel> todos) async {
    _store
      ..clear()
      ..addAll(todos);
  }
}
