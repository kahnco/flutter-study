// 히트 테스트 — 포인터가 어느 RenderObject 를 맞히는지를 "돌아가는 증명"으로.
//   fvm flutter test test/hittest_test.dart
//
// 큰 그림: 포인터가 내려오면 RenderObject 트리를 훑어 "그 위치에 걸린 것들"을 앞→뒤 순서로 모은다.
//   RenderBox.hitTest 는 (1) 내 size 안인지 → (2) 자식들(앞에 그린 것 먼저) → (3) 나 자신 순.
//   그래서 위(나중에 그린)가 먼저 걸리고, 부모 밖으로 나간 자식은 안 걸린다. 그 결과가 8편의 아레나로 간다.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: Center(child: child));

GestureDetector _gd(VoidCallback onTap) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(width: 200, height: 200),
    );

void main() {
  testWidgets('위(나중에 그린 것)가 먼저 히트된다 — 위가 탭을 먹는다', (tester) async {
    var bottom = 0, top = 0;
    // Stack 은 마지막 자식이 위. hitTest 는 앞(위)부터 보므로 top 이 먼저 걸리고 opaque 라 흡수.
    await tester.pumpWidget(_wrap(Stack(children: [_gd(() => bottom++), _gd(() => top++)])));

    await tester.tapAt(tester.getCenter(find.byType(Stack)));
    await tester.pump();

    expect(top, 1, reason: '위에 있는 것이 먼저 히트되어 탭을 먹는다');
    expect(bottom, 0, reason: '아래는 위가 흡수해서 못 받는다');
  });

  testWidgets('IgnorePointer 는 히트에서 빠져 뒤로 통과시킨다', (tester) async {
    var back = 0, front = 0;
    await tester.pumpWidget(_wrap(Stack(children: [
      _gd(() => back++), // 뒤
      IgnorePointer(child: _gd(() => front++)), // 위지만 히트에서 투명
    ])));

    await tester.tapAt(tester.getCenter(find.byType(Stack)));
    await tester.pump();

    expect(front, 0, reason: 'IgnorePointer 로 감싼 위쪽은 히트되지 않는다');
    expect(back, 1, reason: '포인터가 뒤로 통과해 뒤쪽이 받는다');
  });

  testWidgets('AbsorbPointer 는 자기가 먹고 뒤까지 막는다', (tester) async {
    var back = 0, front = 0;
    await tester.pumpWidget(_wrap(Stack(children: [
      _gd(() => back++), // 뒤
      AbsorbPointer(child: _gd(() => front++)), // 위: 흡수(자식·뒤 모두 차단)
    ])));

    await tester.tapAt(tester.getCenter(find.byType(Stack)));
    await tester.pump();

    expect(front, 0, reason: 'AbsorbPointer 자식은 이벤트를 못 받는다');
    expect(back, 0, reason: '뒤쪽도 막힌다 — 흡수했으니까');
  });
}
