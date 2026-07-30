// 미니 Provider 증명 — watch 한 위젯만 리빌드되고, read 만 한 위젯은 안 된다.
//   fvm flutter test test/mini_provider_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_study/mini_provider.dart';

/// 사용자 모델 — Store 를 상속.
class CounterStore extends Store {
  int count = 0;
  void increment() {
    count++;
    notifyListeners(); // 값 바뀜을 알린다
  }
}

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('watch 한 위젯만 리빌드되고, read 만 한 위젯은 리빌드되지 않는다', (tester) async {
    var watcherBuilds = 0;
    var readerBuilds = 0;
    late CounterStore store;

    await tester.pumpWidget(_wrap(
      Provide<CounterStore>(
        create: () {
          store = CounterStore();
          return store;
        },
        // child 는 여기서 한 번만 만들어 넘긴다 → Provider 리빌드 시 구조적 재빌드 없음
        child: Column(
          children: [
            // watch: 구독 → 값 바뀌면 리빌드
            Builder(builder: (context) {
              watcherBuilds++;
              return Text('${context.watch<CounterStore>().count}',
                  textDirection: TextDirection.ltr);
            }),
            // read 도 안 하는(구독 없는) 위젯 → 절대 리빌드되면 안 됨
            Builder(builder: (context) {
              readerBuilds++;
              return const SizedBox();
            }),
          ],
        ),
      ),
    ));

    expect(watcherBuilds, 1);
    expect(readerBuilds, 1);

    // 값 변경
    store.increment();
    await tester.pump();

    expect(watcherBuilds, 2, reason: 'watch 한 위젯은 리빌드된다');
    expect(readerBuilds, 1, reason: '구독 안 한 위젯은 리빌드되지 않는다 — Provider 의 핵심');

    // 화면에도 새 값이 반영됐다
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('read 는 콜백에서 store 를 꺼내 쓰되, 그 위젯을 구독시키지 않는다', (tester) async {
    var hostBuilds = 0;
    late CounterStore captured;

    await tester.pumpWidget(_wrap(
      Provide<CounterStore>(
        create: CounterStore.new,
        child: Builder(builder: (context) {
          hostBuilds++;
          // read 로 store 를 꺼낸다 — onPressed 콜백에서 쓰는 그 패턴. 이 위젯은 구독하지 않는다.
          captured = context.read<CounterStore>();
          return const SizedBox();
        }),
      ),
    ));

    expect(hostBuilds, 1);

    // read 로 꺼낸 store 로 값을 바꾼다(콜백에서 하는 일). 이 위젯은 watch 를 안 했으니 리빌드 안 됨.
    captured.increment();
    await tester.pump();

    expect(captured.count, 1, reason: 'read 로 꺼낸 store 로 값이 실제로 바뀐다');
    expect(hostBuilds, 1, reason: 'read 만 한 위젯은 값이 바뀌어도 리빌드되지 않는다');
  });
}
