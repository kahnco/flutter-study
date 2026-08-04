// 할 일 화면 위젯 테스트 — fake 그래프(인메모리)로 화면을 띄우고, 사용자 동작이
// 이벤트를 던져 상태가 화면에 반영되는지 끝까지 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_study/core/di/injection.dart';
import 'package:flutter_study/features/todos/presentation/pages/todos_page.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_input_field.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_tile.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_scope.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_search_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // configureDependencies 는 이제 Future 를 돌려준다. setUp 이 그 Future 를
  // 기다려 주므로, 화면을 띄우기 전에 그래프가 준비된다.
  setUp(() => configureDependencies(environment: 'fake'));
  tearDown(() => getIt.reset());

  // 화면에 TextField 가 둘(입력·검색)이라, 각각을 조상 위젯으로 특정한다.
  final addField = find.descendant(
    of: find.byType(TodoInputField),
    matching: find.byType(TextField),
  );
  final searchField = find.descendant(
    of: find.byType(TodosSearchField),
    matching: find.byType(TextField),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TodosScope(child: TodosPage())),
    );
    await tester.pumpAndSettle(); // TodosStarted → 빈 목록까지
  }

  Future<void> addTodo(WidgetTester tester, String title) async {
    await tester.enterText(addField, title);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  testWidgets('처음엔 빈 목록 안내가 뜬다', (tester) async {
    await pumpApp(tester);
    expect(find.byType(TodoTile), findsNothing);
    expect(find.textContaining('할 일이 없습니다'), findsOneWidget);
  });

  testWidgets('입력하고 추가하면 목록에 뜬다', (tester) async {
    await pumpApp(tester);

    await addTodo(tester, '우유 사기');

    expect(find.text('우유 사기'), findsOneWidget);
    expect(find.byType(TodoTile), findsOneWidget);
  });

  testWidgets('빈 제목을 넣으면 오류 문구가 뜨고 추가되지 않는다', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add)); // 빈 필드로 제출
    await tester.pumpAndSettle();

    expect(find.text('할 일을 입력하세요'), findsOneWidget);
    expect(find.byType(TodoTile), findsNothing);
  });

  testWidgets('체크박스를 누르면 완료로 토글된다', (tester) async {
    await pumpApp(tester);

    await addTodo(tester, '청소');

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('휴지통을 누르면 목록에서 사라진다', (tester) async {
    await pumpApp(tester);

    await addTodo(tester, '버릴 것');
    expect(find.byType(TodoTile), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(TodoTile), findsNothing);
  });

  testWidgets('검색어를 입력하면(디바운스 뒤) 목록이 좁아진다', (tester) async {
    await pumpApp(tester);
    await addTodo(tester, '우유 사기');
    await addTodo(tester, '청소하기');
    expect(find.byType(TodoTile), findsNWidgets(2));

    await tester.enterText(searchField, '우유');
    // 디바운스(기본 300ms) 전에는 아직 그대로다.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TodoTile), findsNWidgets(2));

    // 디바운스 경과 → 질의 → 결과 반영.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(TodoTile), findsOneWidget);
    expect(find.text('우유 사기'), findsOneWidget);
    expect(find.text('청소하기'), findsNothing);
  });

  testWidgets('필터 탭을 누르면 완료/미완료로 걸러진다', (tester) async {
    await pumpApp(tester);
    await addTodo(tester, '우유 사기');
    await addTodo(tester, '청소하기');

    // 첫 항목만 완료 처리
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // '완료' 탭 → 완료된 것만
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.byType(TodoTile), findsOneWidget);

    // '미완료' 탭 → 미완료만
    await tester.tap(find.text('미완료'));
    await tester.pumpAndSettle();
    expect(find.byType(TodoTile), findsOneWidget);
    expect(find.text('청소하기'), findsOneWidget);
  });
}
