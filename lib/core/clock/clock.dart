import 'package:injectable/injectable.dart';

/// 현재 시각 공급자. 시간을 직접 DateTime.now() 로 읽지 않고 이 인터페이스로 주입받아,
/// 테스트에서 시간을 고정할 수 있게 한다(cross-cutting: 인터페이스 + prod/fake).
abstract interface class Clock {
  DateTime now();
}

@LazySingleton(as: Clock, env: ['prod'])
class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

@LazySingleton(as: Clock, env: ['fake'])
class FixedClock implements Clock {
  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(0);
}
