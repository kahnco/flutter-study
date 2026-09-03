import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_edit_dialog.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';

/// 할 일 한 줄. 체크박스로 토글, 휴지통으로 삭제, 줄을 탭하면 제목 수정.
class TodoTile extends StatelessWidget {
  const TodoTile({super.key, required this.todo});

  final Todo todo;

  Future<void> _edit(BuildContext context) async {
    final bloc = TodosBlocProvider.of(context); // await 전에 잡아 둔다.
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => TodoEditDialog(initial: todo.title.value),
    );
    if (newTitle != null) bloc.add(TodoEdited(todo.id, newTitle));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = TodosBlocProvider.of(context);
    return ListTile(
      onTap: () => _edit(context),
      leading: Checkbox(
        value: todo.completed,
        onChanged: (_) => bloc.add(TodoToggled(todo.id)),
      ),
      title: Text(
        todo.title.value,
        style: todo.completed
            ? const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              )
            : null,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: '삭제',
        onPressed: () => bloc.add(TodoRemoved(todo.id)),
      ),
    );
  }
}
