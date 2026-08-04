import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';

/// 제목 검색창. 입력이 바뀔 때마다 [SearchChanged] 를 던진다.
/// 상태에서 값을 되받지 않고(자기 컨트롤러가 진실원천), 재조정으로 포커스를
/// 잃지 않게 자기 State 를 유지한다(지하 탐사 2편의 그 재조정이다).
class TodosSearchField extends StatefulWidget {
  const TodosSearchField({super.key});

  @override
  State<TodosSearchField> createState() => _TodosSearchFieldState();
}

class _TodosSearchFieldState extends State<TodosSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          TodosBlocProvider.of(context).add(SearchChanged(value));
          setState(() {}); // 지우기 아이콘 표시 갱신
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: '제목 검색',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: '지우기',
                  onPressed: () {
                    _controller.clear();
                    TodosBlocProvider.of(context).add(const SearchChanged(''));
                    setState(() {}); // suffixIcon 갱신
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
