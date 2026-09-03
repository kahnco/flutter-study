import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// 페이지 커서. "마지막으로 본 항목"의 정렬 키 `(createdAtMillis, id)`.
/// keyset 페이징은 offset 대신 이 커서 **이후**를 조회한다(9편).
class TodoCursor extends Equatable {
  const TodoCursor({required this.createdAtMillis, required this.id});

  final int createdAtMillis;
  final String id;

  @override
  List<Object?> get props => [createdAtMillis, id];
}

/// 목록 조회 조건. 완료 상태 필터, 제목 검색어, 페이지 크기([limit]),
/// 그리고 keyset 커서([after]) — [after] 가 null 이면 첫 페이지.
/// 정렬은 `created_at ASC, id ASC` 고정(커서 비교 키와 일치해야 정합).
class TodoQuery extends Equatable {
  const TodoQuery({
    this.status = TodosFilter.all,
    this.text = '',
    this.limit,
    this.after,
  });

  final TodosFilter status;
  final String text;
  final int? limit;
  final TodoCursor? after;

  @override
  List<Object?> get props => [status, text, limit, after];
}
