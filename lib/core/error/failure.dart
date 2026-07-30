import 'package:equatable/equatable.dart';

/// 앱 전역의 실패 타입. data 계층에서 잡힌 예외를 이 sealed 타입으로 바꿔
/// usecase·bloc 까지 Either 로 흘린다. UI 는 예외를 직접 보지 않는다.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// 로컬 저장소(캐시) 접근 실패.
class CacheFailure extends Failure {
  const CacheFailure([super.message = '저장소에 접근하지 못했습니다']);
}

/// 도메인 규칙(값 검증) 위반.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 분류되지 않은 예상 밖 오류.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = '알 수 없는 오류가 발생했습니다']);
}
