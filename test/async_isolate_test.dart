// 비동기·스레드 — "돌아가는 증명"으로.
//   fvm flutter test test/async_isolate_test.dart
//
// 큰 그림: Dart 코드는 한 아이솔레이트의 "이벤트 루프" 하나에서 돈다(단일 스레드).
//   실행 순서는 항상: (1) 지금 동기 코드 → (2) 마이크로태스크 큐 전부 → (3) 이벤트 큐에서 하나
//   → 다시 (2) → (3) … async/await 는 새 스레드가 아니라, 이 루프에 "이어서 실행"을 예약하는 것.
//   무거운 계산은 이 루프를 막아 프레임을 멈춘다 → 그래서 Isolate(별도 힙+스레드)로 넘긴다.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';

// 아이솔레이트별로 복사되는(공유 안 되는) 최상위 상태 — 별도 힙 증명용.
int globalCounter = 0;

void main() {
  test('실행 순서: 동기 코드 → 마이크로태스크 → 이벤트', () async {
    final order = <String>[];

    order.add('sync-1');
    scheduleMicrotask(() => order.add('microtask-1')); // 마이크로태스크 큐
    Future(() => order.add('event-1')); // 이벤트 큐(태스크)
    Future.microtask(() => order.add('microtask-2')); // 마이크로태스크 큐
    order.add('sync-2');

    // 루프를 한 바퀴 돌려 큐를 비운다(이 await 의 이벤트는 event-1 뒤에 처리된다).
    await Future<void>(() {});

    expect(order, [
      'sync-1', 'sync-2', // 지금 동기 코드가 먼저
      'microtask-1', 'microtask-2', // 그다음 마이크로태스크 전부
      'event-1', // 마지막에 이벤트 큐
    ]);
  });

  test('async 함수 첫 줄은 동기 실행, await 에서 루프에 양보한다', () async {
    final order = <String>[];

    Future<void> foo() async {
      order.add('foo-start'); // 호출 즉시 동기로 실행된다
      await null; // 여기서 이벤트 루프에 양보
      order.add('foo-after-await'); // 나중에 마이크로태스크로 재개
    }

    order.add('before');
    final f = foo(); // foo-start 가 여기서 "즉시" 실행됨(아직 await 전)
    order.add('after-call');
    await f;

    expect(order, ['before', 'foo-start', 'after-call', 'foo-after-await']);
  });

  test('마이크로태스크는 다음 이벤트 전에 모두 비워진다', () async {
    final order = <String>[];

    Future(() {
      order.add('event-A');
      // 이벤트 A 를 처리하는 도중 예약한 마이크로태스크는, 이벤트 B 보다 먼저 실행된다.
      scheduleMicrotask(() => order.add('microtask-in-A'));
    });
    Future(() => order.add('event-B'));

    await Future<void>(() {});

    expect(order, ['event-A', 'microtask-in-A', 'event-B']);
  });

  test('Isolate: 별도 힙(공유 안 됨) + 무거운 계산을 넘겨 결과만 받는다', () async {
    globalCounter = 100;

    // 새 아이솔레이트는 자기 힙에서 top-level 을 새로 초기화(0)한 뒤 +1 → 1.
    final inIsolate = await Isolate.run(() => ++globalCounter);
    expect(inIsolate, 1, reason: '새 아이솔레이트는 메인의 100 을 못 본다 — 힙 분리');
    expect(globalCounter, 100, reason: '메인 힙은 그대로 — 공유 안 됨');

    // CPU 무거운 계산을 다른 아이솔레이트(=다른 스레드)로 넘긴다. UI 루프를 안 막는다.
    final sum = await Isolate.run(() {
      var s = 0;
      for (var i = 0; i < 1000000; i++) {
        s += i;
      }
      return s;
    });
    expect(sum, 499999500000);
  });
}
