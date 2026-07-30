// 애니메이션 내부 — Ticker·AnimationController 를 "돌아가는 증명"으로.
//   fvm flutter test test/animation_test.dart
//
// 큰 그림: AnimationController 는 Ticker 로 매 프레임(vsync) 깨어나, 흐른 시간만큼 값(0→1)을
//   전진시키고 리스너에게 알린다. 리스너(AnimatedBuilder)는 그 프레임의 build 에서 리빌드된다.
//   즉 애니메이션은 별도 스레드가 아니라 "프레임마다 값을 조금씩 바꾸는 것"이다(6편의 그 파이프라인).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('AnimationController 는 흐른 시간만큼 값을 전진시킨다(vsync 프레임 구동)', (tester) async {
    late AnimationController c;
    await tester.pumpWidget(_wrap(_Anim((ctrl) => c = ctrl)));

    expect(c.value, 0.0);

    await tester.pump(const Duration(milliseconds: 500)); // 1초짜리의 절반
    expect(c.value, closeTo(0.5, 0.02));

    await tester.pump(const Duration(milliseconds: 600)); // 나머지(살짝 오버슈트 → 확실히 완료)
    expect(c.value, 1.0);
    expect(c.status, AnimationStatus.completed);

    await tester.pumpWidget(_wrap(const SizedBox())); // 위젯 제거 → controller.dispose
  });

  testWidgets('애니메이션이 도는 동안 리스너(AnimatedBuilder)는 프레임마다 리빌드된다', (tester) async {
    var builds = 0;
    await tester.pumpWidget(_wrap(_Anim((_) {}, onBuild: () => builds++)));
    final before = builds;

    await tester.pump(const Duration(milliseconds: 16)); // 한 프레임 진행
    expect(builds, greaterThan(before), reason: '틱마다 값이 바뀌어 리빌드된다');

    await tester.pumpWidget(_wrap(const SizedBox()));
  });

  test('Tween 과 Curve 는 순수 매핑이다 — 0..1 을 값/곡선으로', () {
    // Tween: 0..1 → begin..end 선형 보간
    expect(Tween<double>(begin: 10, end: 20).transform(0.0), 10);
    expect(Tween<double>(begin: 10, end: 20).transform(0.5), 15);
    expect(Tween<double>(begin: 10, end: 20).transform(1.0), 20);

    // Curve: 0..1 → 0..1 (양끝 고정), easeIn 은 초반이 느리다
    expect(Curves.easeIn.transform(0.0), 0.0);
    expect(Curves.easeIn.transform(1.0), 1.0);
    expect(Curves.easeIn.transform(0.5), lessThan(0.5));
  });
}

/// AnimationController 를 만들어 forward 하고, AnimatedBuilder 로 리스너를 건다.
class _Anim extends StatefulWidget {
  const _Anim(this.expose, {this.onBuild});
  final void Function(AnimationController) expose;
  final VoidCallback? onBuild;

  @override
  State<_Anim> createState() => _AnimState();
}

class _AnimState extends State<_Anim> with SingleTickerProviderStateMixin {
  // vsync: this — 이 위젯의 Ticker 를 스케줄러 프레임에 물린다.
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    widget.expose(c);
    c.forward();
  }

  @override
  void dispose() {
    c.dispose(); // 반드시 정리 — 안 그러면 Ticker 가 남는다
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c, // 값이 바뀔 때마다 이 builder 가 다시 불린다
      builder: (_, _) {
        widget.onBuild?.call();
        return const SizedBox();
      },
    );
  }
}
