// 제스처 — GestureDetector·제스처 아레나를 "돌아가는 증명"으로.
//   fvm flutter test test/gesture_test.dart
//
// 큰 그림: 포인터가 내려오면(PointerDown) 여러 제스처 인식기(tap·drag·scroll…)가 "아레나"에
//   들어가 경쟁한다. 포인터가 움직인 정도 등으로 하나가 이기고(예: 충분히 끌면 drag 승), 나머지는
//   진다. 그래서 "끌면 탭이 취소"되는 것. Listener 는 그 아래 원시 포인터를 아레나와 무관하게 받는다.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: Center(child: child));

void main() {
  testWidgets('아레나: 탭하면 onTap, 끌면 onTap 대신 드래그가 이긴다', (tester) async {
    var taps = 0;
    var drags = 0;

    await tester.pumpWidget(_wrap(GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => taps++,
      onPanUpdate: (_) => drags++,
      child: const SizedBox(width: 200, height: 200),
    )));

    // 움직임 없는 탭 → tap 이 아레나에서 이긴다
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(taps, 1);
    expect(drags, 0);

    // 충분히 끌기 → drag 가 이기고 tap 은 진다(취소)
    await tester.drag(find.byType(GestureDetector), const Offset(120, 0));
    await tester.pump();
    expect(drags, greaterThan(0), reason: '끌면 드래그가 아레나에서 이긴다');
    expect(taps, 1, reason: '끄는 동안 탭은 발동하지 않는다(취소)');
  });

  testWidgets('Listener 는 아레나와 무관하게 원시 포인터를 받는다', (tester) async {
    var pointerDowns = 0;
    var taps = 0;

    await tester.pumpWidget(_wrap(Listener(
      onPointerDown: (_) => pointerDowns++,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: const SizedBox(width: 200, height: 200),
      ),
    )));

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(pointerDowns, 1); // 원시 포인터
    expect(taps, 1); // 제스처

    // 끌기: 탭은 안 되지만, 원시 PointerDown 은 그대로 온다
    await tester.drag(find.byType(GestureDetector), const Offset(120, 0));
    await tester.pump();
    expect(pointerDowns, 2, reason: 'Listener 는 아레나 결과와 무관하게 매 포인터를 받는다');
    expect(taps, 1);
  });

  testWidgets('HitTestBehavior.opaque 는 빈 영역도 탭을 잡게 한다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(GestureDetector(
      behavior: HitTestBehavior.opaque, // 그리는 게 없어도 이 영역을 히트 대상으로 만든다
      onTap: () => taps++,
      child: const SizedBox(width: 120, height: 120),
    )));

    await tester.tapAt(tester.getCenter(find.byType(GestureDetector)));
    await tester.pump();
    expect(taps, 1, reason: 'opaque 라서 투명한 SizedBox 영역의 탭도 잡힌다');
  });
}
