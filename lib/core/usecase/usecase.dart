import 'package:fpdart/fpdart.dart';
import 'package:flutter_study/core/error/failure.dart';

/// 유스케이스 계약. 입력 [In] 을 받아 `Either<Failure, Out>` 를 돌려준다.
/// usecase 는 얇게 — 대개 repository 호출을 그대로 전달(pass-through)한다.
abstract interface class UseCase<Out, In> {
  Future<Either<Failure, Out>> call(In params);
}

/// 입력이 없는 유스케이스용 빈 파라미터.
class NoParams {
  const NoParams();
}
