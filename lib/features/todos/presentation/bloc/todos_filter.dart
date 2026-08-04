/// 완료 상태로 목록을 거르는 탭. label 은 화면 세그먼트에 그대로 쓴다.
enum TodosFilter {
  all('전체'),
  active('미완료'),
  completed('완료');

  const TodosFilter(this.label);
  final String label;
}
