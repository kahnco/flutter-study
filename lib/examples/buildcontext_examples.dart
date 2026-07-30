// BuildContext 글에 붙이는 "실제로 이렇게 쓴다" 예제 모음.
// 전부 컴파일되는 진짜 위젯 코드다(fvm flutter analyze 로 검증).
//
// - Greeting        : 위젯 하나가 Element 하나로 부풀려지는 최소 예
// - Counter         : setState — Widget 은 갈아끼워지고 State/Element 는 유지
// - CounterScope..  : InheritedWidget 로 만든 미니 Provider(값 내려주기 + 구독)
// - openDetail      : async gap 뒤 context.mounted 로 안전하게 context 쓰기
// - sumHeavy        : 무거운 계산을 다른 아이솔레이트로 — context 는 넘길 수 없다

import 'dart:isolate';

import 'package:flutter/material.dart';

/// 위젯 하나 = Element 하나. 이 Greeting 은 런타임에 StatelessElement 로 부풀려지고,
/// 그 Element 가 build 의 context 로 넘어온다.
class Greeting extends StatelessWidget {
  const Greeting(this.name, {super.key});
  final String name;

  @override
  Widget build(BuildContext context) => Text('안녕, $name');
}

/// setState 는 위젯을 바꾸지 않는다 — 새 위젯을 같은 Element 에 갈아끼운다.
/// _count 는 State 에 있고, 그 State 를 StatefulElement 가 붙들고 있어 리빌드해도 유지된다.
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0; // ← 리빌드해도 살아남는 상태(Element 가 들고 있음)

  @override
  Widget build(BuildContext context) {
    // onPressed 마다 setState → 새 build → 새 Widget 트리, 그러나 같은 Element·State.
    return TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('$_count'),
    );
  }
}

// ── InheritedWidget 로 만든 미니 Provider ──────────────────────────
// Provider·Riverpod 이 감싸고 있는 알맹이가 사실 이것이다.

/// 값(count)과 동작(increment)을 자손에게 내려주는 InheritedWidget.
class CounterScope extends InheritedWidget {
  const CounterScope({
    super.key,
    required this.count,
    required this.increment,
    required super.child,
  });

  final int count;
  final VoidCallback increment;

  /// of(context) — 여기서 dependOn... 이 "구독"을 건다.
  /// 이 context 는 count 가 바뀔 때마다 리빌드된다.
  static CounterScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CounterScope>()!;

  @override
  bool updateShouldNotify(CounterScope oldWidget) => oldWidget.count != count;
}

/// 상태를 쥐고 CounterScope 를 공급하는 위젯. setState 로 값을 바꾸면
/// CounterScope 가 새 값으로 교체되고, 구독한 자손만 리빌드된다.
class CounterProvider extends StatefulWidget {
  const CounterProvider({super.key, required this.child});
  final Widget child;

  @override
  State<CounterProvider> createState() => _CounterProviderState();
}

class _CounterProviderState extends State<CounterProvider> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return CounterScope(
      count: _count,
      increment: () => setState(() => _count++),
      child: widget.child,
    );
  }
}

/// 소비자 — of(context) 로 구독. count 가 바뀌면 이 위젯"만" 리빌드된다.
class CounterLabel extends StatelessWidget {
  const CounterLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CounterScope.of(context); // 구독 등록 + 값 읽기
    return Text('${scope.count}');
  }
}

/// 미니 Provider 를 조립한 데모 화면.
class MiniProviderDemo extends StatelessWidget {
  const MiniProviderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return CounterProvider(
      child: Column(
        children: [
          const CounterLabel(), // count 바뀌면 이 자손만 리빌드
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CounterScope.of(context).increment(),
              child: const Text('+1'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── async gap 뒤 context 안전하게 쓰기 ────────────────────────────

/// await 사이에 프레임이 지나 위젯이 사라졌을 수 있다.
/// context.mounted 로 살아있을 때만 context 를 만진다.
Future<void> openDetail(BuildContext context, Future<String> Function() fetch) async {
  final data = await fetch(); // ← 이 사이 이 위젯이 트리에서 빠졌을 수 있다
  if (!context.mounted) return; // 죽었으면 여기서 멈춘다(안 그러면 예외/경고)
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data)));
}

// ── 무거운 일은 다른 아이솔레이트로 ───────────────────────────────

/// 큰 계산을 UI 스레드에서 하면 프레임이 밀린다. 별도 아이솔레이트로 넘긴다.
/// 넘어가는 건 순수 데이터(int)뿐 — BuildContext 는 절대 못 넘긴다(힙이 분리됨).
Future<int> sumHeavy(int n) => Isolate.run(() {
      var sum = 0;
      for (var i = 0; i < n; i++) {
        sum += i;
      }
      return sum; // 결과를 받아 UI 아이솔레이트에서 setState 한다
    });
