// 재조정(reconciliation)과 Key — "돌아가는 증명"으로.
//   fvm flutter test test/reconciliation_key_test.dart
//
// 큰 그림: 부모가 리빌드하면, Flutter 는 같은 자리의 [옛 Element] 와 [새 Widget] 을 비교해
//   1) 인스턴스가 identical → 그 서브트리 통째로 스킵(const 가 빠른 이유)
//   2) Widget.canUpdate(같은 runtimeType + 같은 key) → 기존 Element 재사용(State 유지)
//   3) 아니면 옛 Element 해체 + 새 Element 생성(State 리셋)
// 이 판정이 어디에 State 가 붙느냐를 결정한다. Key 는 그 판정을 "위치"에서 "정체"로 바꾼다.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('1. canUpdate — 재사용 판정 규칙', () {
    test('같은 타입 + 같은 key 면 true, 아니면 false', () {
      expect(Widget.canUpdate(const SizedBox(), const SizedBox()), isTrue);
      expect(
        Widget.canUpdate(
          const SizedBox(key: ValueKey('a')),
          const SizedBox(key: ValueKey('a')),
        ),
        isTrue,
      );
      // 같은 타입이지만 key 가 다르면 → 재사용 불가
      expect(
        Widget.canUpdate(
          const SizedBox(key: ValueKey('a')),
          const SizedBox(key: ValueKey('b')),
        ),
        isFalse,
      );
      // 타입이 다르면 → 재사용 불가
      expect(Widget.canUpdate(const SizedBox(), const Padding(padding: EdgeInsets.zero)), isFalse);
    });
  });

  group('2. identical(const) 위젯은 리빌드를 통째로 건너뛴다', () {
    testWidgets('const 자식은 부모가 리빌드해도 다시 build 되지 않는다', (tester) async {
      _CountingLeaf.builds = 0;

      // const 는 canonical 인스턴스라, 두 번 써도 identical → updateChild 가 스킵한다.
      Widget tree(String text) => _wrap(Column(children: [Text(text), const _CountingLeaf()]));

      await tester.pumpWidget(tree('a')); // leaf build 1회
      await tester.pumpWidget(tree('b')); // Text 만 바뀜, leaf 는 identical → 스킵

      expect(_CountingLeaf.builds, 1, reason: 'const(identical) 자식은 리빌드되지 않는다');
    });
  });

  group('3. 같은 타입이면 State 유지, 타입이 바뀌면 리셋', () {
    testWidgets('같은 자리·같은 타입 → 같은 State(카운트 유지), 타입 교체 → 새 State(리셋)',
        (tester) async {
      await tester.pumpWidget(_wrap(const _Counter()));
      final state1 = tester.state<_CounterState>(find.byType(_Counter));
      state1.increment();
      await tester.pump();
      expect(state1.count, 1);

      // 같은 타입으로 다시 → canUpdate true → 같은 Element·State
      await tester.pumpWidget(_wrap(const _Counter()));
      final state2 = tester.state<_CounterState>(find.byType(_Counter));
      expect(identical(state1, state2), isTrue);
      expect(state2.count, 1, reason: '같은 타입이면 State 가 유지된다');

      // 타입을 바꿨다가 → 옛 Element 해체
      await tester.pumpWidget(_wrap(const SizedBox()));
      // 다시 _Counter → 새 Element·새 State
      await tester.pumpWidget(_wrap(const _Counter()));
      final state3 = tester.state<_CounterState>(find.byType(_Counter));
      expect(identical(state1, state3), isFalse);
      expect(state3.count, 0, reason: '타입이 바뀌면 State 가 리셋된다');
    });
  });

  group('4. 리스트: Key 없으면 State 가 위치에 붙고, Key 주면 항목을 따라간다', () {
    // 각 _Tile 의 State 는 initState 에서 고유 stateId 를 받는다(= "이 항목의 내부 상태").
    Map<String, int> labelToStateId(WidgetTester t) {
      final map = <String, int>{};
      for (final s in t.stateList<_TileState>(find.byType(_Tile))) {
        map[s.widget.label] = s.stateId;
      }
      return map;
    }

    testWidgets('Key 없음 → 순서를 뒤집으면 State 가 항목을 안 따라간다(버그)', (tester) async {
      _tileSeq = 0;
      await tester.pumpWidget(_wrap(Column(children: const [_Tile('A'), _Tile('B')])));
      final before = labelToStateId(tester); // {A:0, B:1}

      // 순서 뒤집기(key 없음) → 위치별로 Element 재사용, label 만 갱신됨
      await tester.pumpWidget(_wrap(Column(children: const [_Tile('B'), _Tile('A')])));
      final after = labelToStateId(tester);

      expect(after, isNot(equals(before)),
          reason: 'State 가 위치에 남아, 항목(label)과 어긋난다 — TextField 텍스트가 엉키는 그 버그');
      // 구체적으로: 위치 0 의 State(id 0)는 그대로인데 이제 label 이 A→B 로 바뀌었다.
    });

    testWidgets('Key 있음 → 순서를 뒤집어도 State 가 항목을 따라간다(수정)', (tester) async {
      _tileSeq = 0;
      await tester.pumpWidget(_wrap(Column(children: const [
        _Tile('A', key: ValueKey('A')),
        _Tile('B', key: ValueKey('B')),
      ])));
      final before = labelToStateId(tester); // {A:0, B:1}

      await tester.pumpWidget(_wrap(Column(children: const [
        _Tile('B', key: ValueKey('B')),
        _Tile('A', key: ValueKey('A')),
      ])));
      final after = labelToStateId(tester);

      expect(after, equals(before),
          reason: 'key 로 매칭 → A 의 State 는 어디로 가든 A 를 따라간다');
    });
  });

  group('5. GlobalKey — State 를 통째로 다른 자리로 옮긴다(재부모화)', () {
    testWidgets('부모를 바꿔도 같은 State, 카운트 유지 + currentState 로 접근', (tester) async {
      final gk = GlobalKey<_CounterState>();

      // 슬롯 0 에 배치
      await tester.pumpWidget(_wrap(Row(children: [_Counter(key: gk), const SizedBox()])));
      gk.currentState!.increment();
      await tester.pump();
      final moved = gk.currentState;
      expect(moved!.count, 1);

      // 같은 GlobalKey 위젯을 "다른 부모(슬롯 1)"로 이동
      await tester.pumpWidget(_wrap(Row(children: [const SizedBox(), _Counter(key: gk)])));

      // 새로 만든 게 아니라 그 State 를 옮겨 왔다 — 인스턴스도 카운트도 그대로.
      expect(identical(gk.currentState, moved), isTrue, reason: 'State 가 재생성이 아니라 이동됨');
      expect(gk.currentState!.count, 1, reason: '이동해도 상태 유지');
    });
  });
}

// ── 테스트용 위젯 ─────────────────────────────────────────────

/// build 될 때마다 static 카운터를 올리는 잎 위젯. const 로 쓰면 identical → 스킵 확인용.
class _CountingLeaf extends StatelessWidget {
  const _CountingLeaf();
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return const SizedBox();
  }
}

/// 내부 상태(count)를 가진 위젯. State 유지/리셋을 관찰한다.
class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  void increment() => setState(() => count++);

  @override
  Widget build(BuildContext context) => Text('$count', textDirection: TextDirection.ltr);
}

/// 리스트 항목. State 마다 고유 stateId 를 부여해 "이 항목의 내부 상태"를 추적한다.
int _tileSeq = 0;

class _Tile extends StatefulWidget {
  const _Tile(this.label, {super.key});
  final String label;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  late final int stateId;

  @override
  void initState() {
    super.initState();
    stateId = _tileSeq++; // 이 State 인스턴스의 고유 도장
  }

  @override
  Widget build(BuildContext context) => Text(widget.label, textDirection: TextDirection.ltr);
}
