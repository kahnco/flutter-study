import 'package:injectable/injectable.dart';

/// 새 엔티티 ID 공급자. 랜덤/시간 기반 대신 인터페이스로 주입해,
/// 테스트에서 결정적인 ID(id-1, id-2 …)를 쓸 수 있게 한다.
abstract interface class IdGenerator {
  String next();
}

@LazySingleton(as: IdGenerator, env: ['prod'])
class TimeIdGenerator implements IdGenerator {
  int _seq = 0;

  @override
  String next() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
}

@LazySingleton(as: IdGenerator, env: ['fake'])
class SequentialIdGenerator implements IdGenerator {
  int _seq = 0;

  @override
  String next() => 'id-${++_seq}';
}
