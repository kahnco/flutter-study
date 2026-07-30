import 'package:injectable/injectable.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';

/// 로컬 저장소 계약. 실패는 예외를 **던진다**(repository 가 잡아 Either 로 바꾼다).
abstract interface class TodoLocalDataSource {
  Future<List<TodoModel>> readAll();
  Future<void> writeAll(List<TodoModel> todos);
}

/// 인메모리 구현. 프로세스가 살아있는 동안만 유지된다 — 재시작하면 사라진다.
/// 지금은 prod 도 이걸 쓴다. 실제 영속(디스크) 어댑터로 prod 를 가르는 건 다음 편.
@LazySingleton(as: TodoLocalDataSource, env: ['prod', 'fake'])
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
