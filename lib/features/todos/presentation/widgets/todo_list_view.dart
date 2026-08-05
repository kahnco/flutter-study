import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_tile.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';

/// 할 일 목록. 비어 있으면 [emptyLabel] 을, 있으면 [TodoTile] 들을 그린다.
/// 바닥 근처까지 스크롤하면 [NextPageRequested] 를 던져 다음 페이지를 잇고,
/// 불러오는 중([loadingMore])이면 맨 아래에 스피너를 얹는다.
class TodoListView extends StatefulWidget {
  const TodoListView({
    super.key,
    required this.todos,
    this.hasMore = false,
    this.loadingMore = false,
    this.emptyLabel = '할 일이 없습니다. 위에서 추가해 보세요.',
  });

  final List<Todo> todos;
  final bool hasMore;
  final bool loadingMore;
  final String emptyLabel;

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  final ScrollController _controller = ScrollController();
  static const double _threshold = 200;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.loadingMore) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _threshold) {
      TodosBlocProvider.of(context).add(const NextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.todos.isEmpty) {
      return Center(
        child: Text(widget.emptyLabel,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    // 로딩 중이면 맨 아래 한 칸을 스피너로 더 그린다.
    final itemCount = widget.todos.length + (widget.loadingMore ? 1 : 0);
    return ListView.separated(
      controller: _controller,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= widget.todos.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return TodoTile(todo: widget.todos[index]);
      },
    );
  }
}
