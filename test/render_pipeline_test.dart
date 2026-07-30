// 렌더 파이프라인 — 한 프레임이 만들어지는 순서를 "돌아가는 증명"으로.
//   fvm flutter test test/render_pipeline_test.dart
//
// 한 프레임(WidgetsBinding.drawFrame)은 정해진 순서로 흐른다:
//   build(dirty Element 리빌드) → layout(flushLayout) → paint(flushPaint)
//   → 레이어 합성/전송 → postFrameCallbacks.
// 그리고 setState 는 "즉시" 리빌드하지 않는다 — dirty 로 표시하고 다음 프레임을 예약할 뿐.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

// 단조 증가 카운터 — 각 단계가 실행되는 "순번"을 찍는다.
int _tick = 0;
int _next() => ++_tick;

int _buildAt = 0, _layoutAt = 0, _paintAt = 0, _postFrameAt = 0;
int _buildCount = 0;

void _resetAll() {
  _tick = _buildAt = _layoutAt = _paintAt = _postFrameAt = _buildCount = 0;
}

void main() {
  testWidgets('한 프레임 순서: build → layout → paint → postFrame', (tester) async {
    _resetAll();
    await tester.pumpWidget(_wrap(const _BuildProbe()));

    expect(_buildAt, greaterThan(0));
    expect(_layoutAt, greaterThan(_buildAt), reason: 'layout 은 build 뒤');
    expect(_paintAt, greaterThan(_layoutAt), reason: 'paint 는 layout 뒤');
    expect(_postFrameAt, greaterThan(_paintAt), reason: 'postFrame 은 paint 뒤');
    // → "build 에서 크기(size)를 못 읽는" 이유: layout 이 build 다음이라, build 시점엔 크기가 없다.
  });

  testWidgets('setState 는 즉시 리빌드하지 않고 다음 프레임을 예약한다', (tester) async {
    _resetAll();
    final key = GlobalKey<_BuildProbeState>();
    await tester.pumpWidget(_wrap(_BuildProbe(key: key)));
    expect(_buildCount, 1);

    key.currentState!.bump(); // setState — dirty 표시 + 프레임 예약
    expect(_buildCount, 1, reason: 'setState 직후엔 아직 리빌드되지 않는다');

    await tester.pump(); // 예약된 프레임 실행
    expect(_buildCount, 2, reason: '프레임이 돌 때 리빌드된다');
  });

  testWidgets('한 프레임 사이 여러 setState 는 리빌드를 한 번으로 합친다(batching)', (tester) async {
    _resetAll();
    final key = GlobalKey<_BuildProbeState>();
    await tester.pumpWidget(_wrap(_BuildProbe(key: key)));
    expect(_buildCount, 1);

    key.currentState!.bump();
    key.currentState!.bump();
    key.currentState!.bump();
    await tester.pump();

    expect(_buildCount, 2, reason: '세 번 setState 해도 한 프레임에 한 번만 리빌드');
  });
}

/// build 순번을 찍는 StatefulWidget. 자식으로 커스텀 렌더(_SeqLeaf)를 둔다.
class _BuildProbe extends StatefulWidget {
  const _BuildProbe({super.key});
  @override
  State<_BuildProbe> createState() => _BuildProbeState();
}

class _BuildProbeState extends State<_BuildProbe> {
  @override
  void initState() {
    super.initState();
    // 프레임 끝(postFrame) 순번을 딱 한 번 기록.
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameAt = _next());
  }

  void bump() => setState(() {});

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _buildAt = _next();
    return const Align(alignment: Alignment.topLeft, child: _SeqLeaf());
  }
}

/// layout·paint 순번을 찍는 잎 렌더 위젯.
class _SeqLeaf extends LeafRenderObjectWidget {
  const _SeqLeaf();
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSeq();
}

class _RenderSeq extends RenderBox {
  @override
  void performLayout() {
    _layoutAt = _next();
    size = constraints.constrain(const Size(10, 10));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintAt = _next();
  }
}
