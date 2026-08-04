import 'package:flutter/material.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_filter.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';

/// 완료 상태 필터 탭(전체·미완료·완료). 현재 선택은 [filter] 로 받아 표시하고,
/// 누르면 [FilterChanged] 를 던진다 — 상태는 bloc 이 쥔다.
class TodosFilterBar extends StatelessWidget {
  const TodosFilterBar({super.key, required this.filter});

  final TodosFilter filter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SegmentedButton<TodosFilter>(
        segments: [
          for (final value in TodosFilter.values)
            ButtonSegment(value: value, label: Text(value.label)),
        ],
        selected: {filter},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => TodosBlocProvider.of(context)
            .add(FilterChanged(selection.first)),
      ),
    );
  }
}
