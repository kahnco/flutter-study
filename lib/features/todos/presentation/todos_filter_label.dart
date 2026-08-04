import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// 도메인 [TodosFilter] 에 화면 표시용 한글 라벨을 붙이는 프레젠테이션 확장.
/// (라벨은 표현이라 도메인 enum 에 두지 않고 여기서 얹는다.)
extension TodosFilterLabel on TodosFilter {
  String get label => switch (this) {
        TodosFilter.all => '전체',
        TodosFilter.active => '미완료',
        TodosFilter.completed => '완료',
      };
}
