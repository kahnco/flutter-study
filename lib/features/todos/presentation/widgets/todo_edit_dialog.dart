import 'package:flutter/material.dart';

/// 제목 수정 다이얼로그. 텍스트만 모아 저장 시 Navigator.pop 으로 돌려준다.
/// 검증(빈 값·과길이)은 bloc 의 값 객체가 하므로, 여기선 날것 문자열만 넘긴다.
class TodoEditDialog extends StatefulWidget {
  const TodoEditDialog({super.key, required this.initial});

  final String initial;

  @override
  State<TodoEditDialog> createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('할 일 수정'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(
          hintText: '할 일',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _save, child: const Text('저장')),
      ],
    );
  }
}
