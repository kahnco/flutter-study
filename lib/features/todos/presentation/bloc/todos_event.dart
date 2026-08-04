import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_filter.dart';

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

/// 제목 검색어를 바꾼다(날것 문자열). 필터와 함께 보이는 목록을 좁힌다.
class SearchChanged extends TodosEvent {
  const SearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}
