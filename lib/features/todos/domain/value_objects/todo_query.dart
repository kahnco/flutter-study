import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// 목록 조회 조건. 저장소가 이 조건으로 걸러 돌려준다 — 완료 상태 필터, 제목 검색어,
/// 그리고 페이지 범위([limit]·[offset]). limit 이 null 이면 제한 없이 전부.
/// 검색·필터를 메모리에서 파생하지 않고(6편) 조회로 내리기로 하면서 도메인에 생긴 값.
class TodoQuery extends Equatable {
  const TodoQuery({
    this.status = TodosFilter.all,
    this.text = '',
    this.limit,
    this.offset = 0,
  });

  final TodosFilter status;
  final String text;
  final int? limit;
  final int offset;

  @override
  List<Object?> get props => [status, text, limit, offset];
}
