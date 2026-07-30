// BuildContext 지하 탐사 — 말이 아니라 "돌아가는 증명"으로.
//
// 이 파일의 각 그룹은 BuildContext 에 대한 한 가지 사실을 런타임에서 증명한다.
//   fvm flutter test test/buildcontext_deep_test.dart
//
// 핵심 명제: "BuildContext 는 별도의 무엇이 아니라, Element 그 자체다."
// Element 트리(살아있는 런타임 트리)의 한 지점을 가리키는 핸들이 곧 BuildContext 다.

import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  group('1. BuildContext 는 사실 Element 다', () {
    testWidgets('build 의 context 는 Element 인스턴스', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      );

      // context 는 Element 를 구현한다(BuildContext 는 Element 가 구현하는 인터페이스).
      expect(captured, isA<Element>());
      // Builder 는 StatelessWidget → 그 자리의 Element 는 StatelessElement.
      expect(captured.runtimeType.toString(), 'StatelessElement');
      // context 로 얻는 widget 은 정확히 이 자리의 위젯.
      expect(captured.widget, isA<Builder>());
    });

    testWidgets('StatefulWidget 자리의 context 는 StatefulElement, State.context 와 동일',
        (tester) async {
      late BuildContext buildCtx;
      late BuildContext stateCtx;
      await tester.pumpWidget(_Probe(onBuild: (ctx, _) => buildCtx = ctx));
      stateCtx = tester.state<_ProbeState>(find.byType(_Probe)).context;

      expect(buildCtx.runtimeType.toString(), 'StatefulElement');
      // State.context 와 build(context) 의 context 는 같은 Element 다.
      expect(identical(buildCtx, stateCtx), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('2. Element 는 오래 살고, Widget 은 매번 갈아끼워진다', () {
    testWidgets('같은 자리를 새 Widget 으로 바꿔도 Element 는 동일 인스턴스', (tester) async {
      final elements = <Element>[];
      final widgets = <Widget>[];

      Widget build(int v) => _Probe(
            value: v,
            onBuild: (ctx, w) {
              elements.add(ctx as Element);
              widgets.add(w);
            },
          );

      await tester.pumpWidget(build(1)); // 첫 mount
      await tester.pumpWidget(build(2)); // 새 _Probe 위젯 주입 → update(교체 아님)

      // Element(=런타임 노드, =context)는 유지된다.
      expect(identical(elements[0], elements[1]), isTrue);
      // Widget(=불변 설정 청사진)은 매번 새 인스턴스로 교체된다.
      expect(identical(widgets[0], widgets[1]), isFalse);
      // 그래서 "context 를 필드에 저장해 두고 재사용"이 (같은 자리인 한) 성립한다.
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('3. context 는 트리 위치다 — 조상으로 걸어 올라갈 수 있다', () {
    testWidgets('visitAncestorElements 로 부모 사슬을 수집', (tester) async {
      late BuildContext leaf;
      await tester.pumpWidget(
        _Marker(
          label: 'A',
          child: _Marker(
            label: 'B',
            child: Builder(builder: (context) {
              leaf = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      final chain = <Type>[];
      leaf.visitAncestorElements((e) {
        chain.add(e.widget.runtimeType);
        return true; // 계속 위로
      });

      // 바로 위(_Marker B)부터 루트 방향으로 조상 위젯 타입이 순서대로 쌓인다.
      expect(chain.first, _Marker); // 가장 가까운 조상
      expect(chain.where((t) => t == _Marker).length, 2); // A, B 둘 다 조상
    });

    testWidgets('findAncestorWidgetOfExactType / findAncestorStateOfType 는 부모 사슬 조회',
        (tester) async {
      late BuildContext leaf;
      await tester.pumpWidget(
        _Probe(
          value: 99,
          child: Builder(builder: (context) {
            leaf = context;
            return const SizedBox();
          }),
        ),
      );

      // 조상에서 특정 위젯/State 를 찾아 올라간다(구독 아님 — 1회 조회, O(깊이)).
      final probe = leaf.findAncestorWidgetOfExactType<_Probe>();
      final state = leaf.findAncestorStateOfType<_ProbeState>();
      expect(probe, isNotNull);
      expect(probe!.value, 99);
      expect(state, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('4. InheritedWidget — context 가 상태를 "구독"하는 진짜 메커니즘', () {
    testWidgets('dependOn 한 자손만 리빌드된다(비의존 자손은 안 됨)', (tester) async {
      var depBuilds = 0;
      var nonDepBuilds = 0;

      // child 서브트리는 테스트에서 딱 한 번 만든다 → 조상이 setState 해도 이 위젯
      // 인스턴스들은 동일(identical)해서 "구조적 리빌드"가 일어나지 않는다.
      // 그러면 오직 InheritedWidget 의존 메커니즘만이 리빌드를 유발한다.
      final child = Column(
        children: [
          Builder(builder: (c) {
            depBuilds++;
            _Model.of(c); // ← 의존 등록(dependOnInheritedWidgetOfExactType)
            return const SizedBox();
          }),
          Builder(builder: (c) {
            nonDepBuilds++; // ← 의존 없음
            return const SizedBox();
          }),
        ],
      );

      final key = GlobalKey<_ProviderState>();
      await tester.pumpWidget(_Provider(key: key, child: child));

      expect(depBuilds, 1);
      expect(nonDepBuilds, 1);

      // InheritedWidget 의 값만 바꾼다(updateShouldNotify == true).
      key.currentState!.bump();
      await tester.pump();

      expect(depBuilds, 2, reason: '의존 자손은 값이 바뀌면 리빌드된다');
      expect(nonDepBuilds, 1, reason: '비의존 자손은 리빌드되지 않는다 — 이것이 핵심');
    });

    testWidgets('dependOnInheritedWidgetOfExactType 는 깊이와 무관하게 O(1) 조회', (tester) async {
      late BuildContext deep;
      // 50겹 깊이로 감싸도, 조회는 미리 계산된 _inheritedElements 맵에서 O(1).
      Widget nest(int n, Widget child) =>
          n == 0 ? child : SizedBox(child: nest(n - 1, child));

      await tester.pumpWidget(
        _Provider(
          child: nest(
            50,
            Builder(builder: (c) {
              deep = c;
              return const SizedBox();
            }),
          ),
        ),
      );

      // 50겹 아래에서도 조상 InheritedWidget 을 곧바로 찾는다.
      expect(_Model.of(deep).value, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('5. context 의 수명 — mounted', () {
    testWidgets('트리에서 빠지면 context.mounted 가 false 가 된다', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_Probe(onBuild: (c, _) => ctx = c));
      expect(ctx.mounted, isTrue);

      // _Probe 를 트리에서 제거 → Element 가 unmount(defunct)됨.
      await tester.pumpWidget(const SizedBox());

      expect(ctx.mounted, isFalse,
          reason: 'async gap 뒤 이 context 를 쓰면 안 되는 이유 — 이미 죽었을 수 있다');
    });
  });

  // ─────────────────────────────────────────────────────────────
  group('6. 스레드/아이솔레이트 — context 는 UI 아이솔레이트에 갇혀 있다', () {
    test('아이솔레이트는 메모리를 공유하지 않는다(= 별도 힙 = context 전달 불가)', () async {
      // 전역 가변 상태를 메인에서 41 로 세팅.
      globalCounter = 41;

      // 다른 아이솔레이트에서 실행 — 자기만의 힙에서 top-level 을 새로 초기화(0)한 뒤 ++.
      final inIsolate = await Isolate.run(() => ++globalCounter);

      expect(inIsolate, 1, reason: '새 아이솔레이트는 메인의 41 을 못 본다 — 힙이 분리됨');
      expect(globalCounter, 41, reason: '메인 힙은 그대로 — 공유되지 않음');

      // 결론: Element/BuildContext 는 참조로도 다른 아이솔레이트에 넘길 수 없다.
      // 위젯·엘리먼트·렌더 트리는 전부 UI(메인) 아이솔레이트의 단일 스레드에서만 산다.
    });
  });
}

// 최상위 가변 상태 — 아이솔레이트별로 복사(공유 아님)됨을 보이기 위한 것.
int globalCounter = 0;

// ── 테스트용 위젯들 ─────────────────────────────────────────────

/// build 시점에 (context, widget) 을 흘려주는 StatefulWidget 프로브.
class _Probe extends StatefulWidget {
  const _Probe({this.value = 0, this.onBuild, this.child});
  final int value;
  final void Function(BuildContext ctx, _Probe widget)? onBuild;
  final Widget? child;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call(context, widget);
    return widget.child ?? const SizedBox();
  }
}

/// 조상 사슬에 표식을 남기는 단순 래퍼.
class _Marker extends StatelessWidget {
  const _Marker({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// 값 하나를 자손에게 내려주는 InheritedWidget + 그걸 갱신하는 StatefulWidget.
class _Provider extends StatefulWidget {
  const _Provider({super.key, required this.child});
  final Widget child;

  @override
  State<_Provider> createState() => _ProviderState();
}

class _ProviderState extends State<_Provider> {
  int _value = 0;
  void bump() => setState(() => _value++);

  @override
  Widget build(BuildContext context) {
    // child 는 widget.child(테스트에서 한 번 만든 동일 인스턴스)를 그대로 전달 →
    // 조상 setState 시 자손 서브트리는 구조적으로 리빌드되지 않는다.
    return _Model(value: _value, child: widget.child);
  }
}

class _Model extends InheritedWidget {
  const _Model({required this.value, required super.child});
  final int value;

  static _Model of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Model>()!;

  @override
  bool updateShouldNotify(_Model oldWidget) => oldWidget.value != value;
}
