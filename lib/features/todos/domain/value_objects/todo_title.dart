import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_study/core/error/failure.dart';

/// 검증된 할 일 제목. 생성은 [create] 로만 — 빈 값·과길이를 도메인에서 막는다.
/// 이미 저장소에 있던(검증을 통과한) 값은 [trusted] 로 되살린다.
class TodoTitle extends Equatable {
  const TodoTitle._(this.value);

  final String value;
  static const int maxLength = 200;

  /// 사용자 입력에서 만든다. 규칙 위반이면 [ValidationFailure].
  static Either<ValidationFailure, TodoTitle> create(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return left(const ValidationFailure('할 일을 입력하세요'));
    }
    if (trimmed.length > maxLength) {
      return left(ValidationFailure('제목은 $maxLength자 이하여야 합니다'));
    }
    return right(TodoTitle._(trimmed));
  }

  /// 저장소에서 읽은(이미 검증된) 값 복원용. data 계층에서만 쓴다.
  factory TodoTitle.trusted(String value) => TodoTitle._(value);

  @override
  List<Object?> get props => [value];
}
