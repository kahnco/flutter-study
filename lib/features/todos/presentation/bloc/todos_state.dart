import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_filter.dart';

/// bloc 에서 나오는 출력. 화면이 그릴 수 있는 **완결된** 한 장면.
sealed class TodosState extends Equatable {
  const TodosState();

  @override
  List<Object?> get props => [];
}

/// 아직 아무것도 불러오지 않은 최초 상태.
class TodosInitial extends TodosState {
  const TodosInitial();
}

/// 목록을 불러오는 중.
class TodosLoading extends TodosState {
  const TodosLoading();
}

/// 목록이 준비된 상태. [todos] 는 **전체**이고, [filter]·[query] 로 [visibleTodos]
/// 를 파생한다 — 저장소는 그대로 두고 보이는 것만 좁히는 프레젠테이션 관심사다.
/// [error] 는 방금 동작이 어긋났을 때만 실리는 **일시적** 메시지(다음 성공에 사라짐).
class TodosLoaded extends TodosState {
  const TodosLoaded(
    this.todos, {
    this.filter = TodosFilter.all,
    this.query = '',
    this.error,
  });

  final List<Todo> todos;
  final TodosFilter filter;
  final String query;
  final String? error;

  /// 필터 탭과 검색어를 전체 목록에 적용한 결과(대소문자 무시, 공백 다듬음).
  List<Todo> get visibleTodos {
    final needle = query.trim().toLowerCase();
    return todos.where((t) {
      final matchesFilter = switch (filter) {
        TodosFilter.all => true,
        TodosFilter.active => !t.completed,
        TodosFilter.completed => t.completed,
      };
      final matchesQuery =
          needle.isEmpty || t.title.value.toLowerCase().contains(needle);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  /// 남은(미완료) 할 일 수 — 화면 요약에 쓴다.
  int get activeCount => todos.where((t) => !t.completed).length;

  @override
  List<Object?> get props => [todos, filter, query, error];
}

/// 목록 자체를 불러오지 못한, 화면 전체가 실패인 상태.
class TodosFailure extends TodosState {
  const TodosFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
