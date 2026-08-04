import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_tile.dart';

/// 할 일 목록. 비어 있으면 [emptyLabel] 을, 있으면 [TodoTile] 들을 그린다.
class TodoListView extends StatelessWidget {
  const TodoListView({
    super.key,
    required this.todos,
    this.emptyLabel = '할 일이 없습니다. 위에서 추가해 보세요.',
  });

  final List<Todo> todos;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      itemCount: todos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => TodoTile(todo: todos[index]),
    );
  }
}
