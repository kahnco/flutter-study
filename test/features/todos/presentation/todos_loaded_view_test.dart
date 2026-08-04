// TodosLoaded 의 파생 뷰(visibleTodos·activeCount)만 순수하게 검증한다 —
// bloc 없이 상태 객체 그 자체로.
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_filter.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_state.dart';
import 'package:flutter_test/flutter_test.dart';

Todo todo(String id, String title, {bool completed = false}) => Todo(
      id: id,
      title: TodoTitle.trusted(title),
      completed: completed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

void main() {
  final todos = [
    todo('1', '우유 사기'),
    todo('2', '청소하기', completed: true),
    todo('3', '우유 데우기'),
  ];

  test('filter=all 이면 전체가 보인다', () {
    final state = TodosLoaded(todos);
    expect(state.visibleTodos.length, 3);
  });

  test('filter=active 는 미완료만', () {
    final state = TodosLoaded(todos, filter: TodosFilter.active);
    expect(state.visibleTodos.map((t) => t.id), ['1', '3']);
  });

  test('filter=completed 는 완료만', () {
    final state = TodosLoaded(todos, filter: TodosFilter.completed);
    expect(state.visibleTodos.map((t) => t.id), ['2']);
  });

  test('검색은 대소문자·공백 무시하고 제목에 포함되면 통과', () {
    final state = TodosLoaded(todos, query: '  우유 ');
    expect(state.visibleTodos.map((t) => t.id), ['1', '3']);
  });

  test('필터와 검색은 함께 적용된다(AND)', () {
    final state = TodosLoaded(
      todos,
      filter: TodosFilter.active,
      query: '우유',
    );
    expect(state.visibleTodos.map((t) => t.id), ['1', '3']);
  });

  test('activeCount 는 미완료 수를 센다', () {
    expect(TodosLoaded(todos).activeCount, 2);
  });
}
