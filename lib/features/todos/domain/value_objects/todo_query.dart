import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// 목록 조회 조건. 저장소가 이 조건으로 걸러 돌려준다 — 완료 상태 필터와 제목 검색어.
/// 검색·필터를 메모리에서 파생하지 않고(6편) 조회로 내리기로 하면서 도메인에 생긴 값.
class TodoQuery extends Equatable {
  const TodoQuery({this.status = TodosFilter.all, this.text = ''});

  final TodosFilter status;
  final String text;

  @override
  List<Object?> get props => [status, text];
}
