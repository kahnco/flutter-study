import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_state.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_input_field.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_list_view.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_filter_bar.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_search_field.dart';

/// 할 일 화면. 스스로 상태를 들지 않고, bloc 의 [state] 스트림을 구독해
/// **완결된 한 장면**을 sealed 상태에 따라 그린다. 사용자 동작은 이벤트로 되던진다.
class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = TodosBlocProvider.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('할 일')),
      body: StreamBuilder<TodosState>(
        stream: bloc.stream,
        initialData: bloc.state, // 늦게 붙는 구독자용 첫 프레임(2편)
        builder: (context, snapshot) {
          final state = snapshot.data!;
          return switch (state) {
            TodosInitial() || TodosLoading() =>
              const Center(child: CircularProgressIndicator()),
            TodosFailure(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => bloc.add(const TodosStarted()),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            final TodosLoaded loaded => Column(
                children: [
                  TodoInputField(error: loaded.error),
                  const TodosSearchField(),
                  TodosFilterBar(filter: loaded.filter),
                  Expanded(
                    child: TodoListView(
                      todos: loaded.todos,
                      hasMore: loaded.hasMore,
                      loadingMore: loaded.loadingMore,
                      emptyLabel: loaded.isFiltered
                          ? '조건에 맞는 할 일이 없습니다.'
                          : '할 일이 없습니다. 위에서 추가해 보세요.',
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}
