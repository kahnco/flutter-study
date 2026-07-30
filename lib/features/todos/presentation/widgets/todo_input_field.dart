import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';

/// 새 할 일을 입력하는 줄. 텍스트 필드가 **날것의 문자열**을 [TodoAdded] 로 던지고,
/// 검증은 bloc 안 값 객체가 한다(2편). [error] 가 있으면 필드 밑에 한 줄로 띄운다.
class TodoInputField extends StatefulWidget {
  const TodoInputField({super.key, this.error});

  final String? error;

  @override
  State<TodoInputField> createState() => _TodoInputFieldState();
}

class _TodoInputFieldState extends State<TodoInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    TodosBlocProvider.of(context).add(TodoAdded(_controller.text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '새 할 일',
                errorText: widget.error,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.add),
            tooltip: '추가',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
