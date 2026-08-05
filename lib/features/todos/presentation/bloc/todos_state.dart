import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

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

/// 목록이 준비된 상태. [todos] 는 **이미 조건([filter]·[query])으로 걸러진** 결과이며,
/// 페이징으로 **여러 페이지가 이어 붙은** 누적 목록이다(8편).
/// [hasMore] 는 더 불러올 페이지가 남았는지, [loadingMore] 는 지금 다음 페이지를
/// 불러오는 중인지. [error] 는 방금 동작이 어긋났을 때만 실리는 일시적 메시지.
class TodosLoaded extends TodosState {
  const TodosLoaded(
    this.todos, {
    this.filter = TodosFilter.all,
    this.query = '',
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final List<Todo> todos;
  final TodosFilter filter;
  final String query;
  final bool hasMore;
  final bool loadingMore;
  final String? error;

  /// 조건이 걸려 있는가 — "결과 없음" 안내 문구를 가르는 데 쓴다.
  bool get isFiltered => filter != TodosFilter.all || query.trim().isNotEmpty;

  @override
  List<Object?> get props => [todos, filter, query, hasMore, loadingMore, error];
}

/// 목록 자체를 불러오지 못한, 화면 전체가 실패인 상태.
class TodosFailure extends TodosState {
  const TodosFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
