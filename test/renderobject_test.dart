// RenderObject 층 — build 아래의 레이아웃/페인트를 "돌아가는 증명"으로.
//   fvm flutter test test/renderobject_test.dart
//
// 레이아웃 규약(세 줄): 제약(constraints)은 내려가고, 크기(size)는 올라오고, 위치는 부모가 정한다.
//   parent 가 child.layout(constraints) 로 제약을 내려주면,
//   child 는 performLayout 에서 그 제약 안으로 size 를 정해 올려 보낸다.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('1. 레이아웃 규약 — 제약은 내려가고 크기는 올라온다', () {
    testWidgets('꽉 조인(tight) 부모는 크기를 강제, 느슨한(loose) 부모는 자식이 정한다', (tester) async {
      // 자식의 "선호 크기"는 80x40. 부모 제약에 따라 실제 크기가 달라진다.
      BoxConstraints? tightC;
      Size? tightS;
      // Align 으로 감싸 SizedBox 가 자기 크기(100x30)를 고를 수 있게 한다.
      // (그러면 SizedBox 는 자식에게 꽉 조인 100x30 제약을 내려준다.)
      await tester.pumpWidget(_wrap(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 100, height: 30, child: _ProbeBox(const Size(80, 40), (c, s) {
            tightC = c;
            tightS = s;
          })),
        ),
      ));
      expect(tightC!.isTight, isTrue, reason: 'SizedBox 는 꽉 조인 제약을 내려준다');
      expect(tightS, const Size(100, 30), reason: '꽉 조이면 선호 크기와 무관하게 부모가 강제');

      BoxConstraints? looseC;
      Size? looseS;
      await tester.pumpWidget(_wrap(
        Align(alignment: Alignment.topLeft, child: _ProbeBox(const Size(80, 40), (c, s) {
          looseC = c;
          looseS = s;
        })),
      ));
      expect(looseC!.isTight, isFalse, reason: 'Align 은 느슨한 제약을 내려준다');
      expect(looseS, const Size(80, 40), reason: '느슨하면 자식이 선호 크기를 고른다');
    });
  });

  group('2. 커스텀 RenderBox 가 실제로 크기를 갖고 트리에 붙는다', () {
    testWidgets('getSize 로 확인', (tester) async {
      await tester.pumpWidget(_wrap(
        Align(alignment: Alignment.topLeft, child: _ProbeBox(const Size(64, 24), (_, _) {})),
      ));
      expect(tester.getSize(find.byType(_ProbeBox)), const Size(64, 24));
    });
  });

  group('3. RepaintBoundary 는 자기 레이어를 가진다', () {
    testWidgets('isRepaintBoundary — 경계는 true, 보통 박스는 false', (tester) async {
      await tester.pumpWidget(_wrap(const RepaintBoundary(child: SizedBox(width: 10, height: 10))));
      expect(tester.renderObject(find.byType(RepaintBoundary)).isRepaintBoundary, isTrue);

      await tester.pumpWidget(_wrap(const SizedBox(width: 10, height: 10)));
      expect(tester.renderObject(find.byType(SizedBox)).isRepaintBoundary, isFalse);
    });
  });

  group('4. relayout boundary — 국소 크기 변경은 조상을 다시 레이아웃하지 않는다', () {
    testWidgets('자식 크기만 바뀌면 그 노드만 performLayout, 조상은 그대로', (tester) async {
      var outer = 0, inner = 0, leaf = 0;

      // outer·inner 는 size 를 "부모 제약만으로" 정하고(자식 크기와 무관) 자식엔 느슨한 제약을 준다
      // → 자식은 relayout boundary 가 된다. 그래서 leaf 크기가 바뀌어도 조상은 안 돈다.
      Widget tree(Size leafSize) => _wrap(
            SizedBox(
              width: 200,
              height: 200,
              child: _CountBox(
                () => outer++,
                child: _CountBox(
                  () => inner++,
                  child: _Resizable(leafSize, () => leaf++),
                ),
              ),
            ),
          );

      await tester.pumpWidget(tree(const Size(50, 50)));
      expect([outer, inner, leaf], [1, 1, 1]);

      // leaf 크기만 바꾼다
      await tester.pumpWidget(tree(const Size(60, 60)));
      expect(leaf, 2, reason: '크기가 바뀐 노드는 다시 레이아웃된다');
      expect(outer, 1, reason: '조상(outer)은 다시 레이아웃되지 않는다');
      expect(inner, 1, reason: '조상(inner)도 다시 레이아웃되지 않는다');
    });
  });
}

// ── 커스텀 RenderObject ─────────────────────────────────────────

/// 받은 제약(내려옴)과 정한 크기(올라감)를 기록하는 잎 렌더 박스.
class _ProbeBox extends LeafRenderObjectWidget {
  const _ProbeBox(this.preferred, this.record);
  final Size preferred;
  final void Function(BoxConstraints constraints, Size size) record;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderProbe(preferred, record);

  @override
  void updateRenderObject(BuildContext context, _RenderProbe renderObject) {
    renderObject.preferred = preferred;
  }
}

class _RenderProbe extends RenderBox {
  _RenderProbe(this.preferred, this.record);
  Size preferred;
  final void Function(BoxConstraints, Size) record;

  @override
  void performLayout() {
    // 제약(부모가 내려준 것) 안으로 선호 크기를 눌러 담아 size 로 올린다.
    size = constraints.constrain(preferred);
    record(constraints, size);
  }
}

/// 자기 크기는 부모 제약만으로 정하고(자식 크기 무관), 자식엔 느슨한 제약을 주는 박스.
/// performLayout 호출을 센다.
class _CountBox extends SingleChildRenderObjectWidget {
  const _CountBox(this.onLayout, {required Widget super.child});
  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCount(onLayout);

  @override
  void updateRenderObject(BuildContext context, _RenderCount renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderCount extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  _RenderCount(this.onLayout);
  VoidCallback onLayout;

  @override
  void performLayout() {
    onLayout();
    size = constraints.biggest; // 자식과 무관하게 부모 제약으로 결정
    child?.layout(BoxConstraints.loose(size)); // 자식엔 느슨하게(parentUsesSize=false)
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child!, offset);
  }
}

/// 크기를 바꿀 수 있는 잎 박스. 크기가 바뀌면 markNeedsLayout.
class _Resizable extends LeafRenderObjectWidget {
  const _Resizable(this.desired, this.onLayout);
  final Size desired;
  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderResizable(desired, onLayout);

  @override
  void updateRenderObject(BuildContext context, _RenderResizable renderObject) {
    renderObject.desired = desired;
  }
}

class _RenderResizable extends RenderBox {
  _RenderResizable(this._desired, this.onLayout);
  Size _desired;
  final VoidCallback onLayout;

  set desired(Size value) {
    if (value != _desired) {
      _desired = value;
      markNeedsLayout(); // 크기가 바뀌었으니 다시 레이아웃 필요
    }
  }

  @override
  void performLayout() {
    onLayout();
    size = constraints.constrain(_desired);
  }
}
