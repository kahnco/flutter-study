// 할 일 화면 위젯 테스트 — fake 그래프(인메모리)로 화면을 띄우고, 사용자 동작이
// 이벤트를 던져 상태가 화면에 반영되는지 끝까지 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_study/core/di/injection.dart';
import 'package:flutter_study/features/todos/presentation/pages/todos_page.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todo_tile.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => configureDependencies(environment: 'fake'));
  tearDown(() => getIt.reset());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TodosScope(child: TodosPage())),
    );
    await tester.pumpAndSettle(); // TodosStarted → 빈 목록까지
  }

  testWidgets('처음엔 빈 목록 안내가 뜬다', (tester) async {
    await pumpApp(tester);
    expect(find.byType(TodoTile), findsNothing);
    expect(find.textContaining('할 일이 없습니다'), findsOneWidget);
  });

  testWidgets('입력하고 추가하면 목록에 뜬다', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), '우유 사기');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

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

    await tester.enterText(find.byType(TextField), '청소');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('휴지통을 누르면 목록에서 사라진다', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), '버릴 것');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TodoTile), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(TodoTile), findsNothing);
  });
}
