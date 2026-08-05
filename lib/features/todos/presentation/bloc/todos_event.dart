import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// bloc 으로 들어가는 입력. 화면은 이 이벤트만 던지고, 로직은 몰라도 된다.
/// sealed 라서 bloc 의 처리부에서 하나라도 빠뜨리면 컴파일러가 잡는다.
sealed class TodosEvent extends Equatable {
  const TodosEvent();

  @override
  List<Object?> get props => [];
}

/// 화면이 처음 뜰 때 — 저장된 할 일을 불러온다.
class TodosStarted extends TodosEvent {
  const TodosStarted();
}

/// 사용자가 입력한 **날것의** 제목. 검증은 bloc 이 값 객체로 한다.
class TodoAdded extends TodosEvent {
  const TodoAdded(this.rawTitle);
  final String rawTitle;

  @override
  List<Object?> get props => [rawTitle];
}

class TodoToggled extends TodosEvent {
  const TodoToggled(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class TodoRemoved extends TodosEvent {
  const TodoRemoved(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// 완료 상태 필터 탭을 바꾼다. 저장소는 건드리지 않고, 보이는 목록만 달라진다.
class FilterChanged extends TodosEvent {
  const FilterChanged(this.filter);
  final TodosFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// 제목 검색어를 바꾼다(날것 문자열). 즉시 질의하지 않고 bloc 이 디바운스한다.
class SearchChanged extends TodosEvent {
  const SearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// 디바운스 타이머가 깨어 "지금 조건으로 다시 질의하라"고 요청하는 내부 이벤트.
/// 화면이 던지는 게 아니라 bloc 이 스스로 큐에 넣는다(순차 처리 유지).
class QueryRefreshed extends TodosEvent {
  const QueryRefreshed();
}

/// 리스트가 바닥에 닿아 다음 페이지를 요청한다(무한 스크롤).
class NextPageRequested extends TodosEvent {
  const NextPageRequested();
}
