import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoTitle.create', () {
    test('앞뒤 공백을 다듬어 값을 만든다', () {
      final result = TodoTitle.create('  우유 사기  ');
      expect(result.getOrElse((_) => TodoTitle.trusted('')).value, '우유 사기');
    });

    test('빈 문자열은 ValidationFailure', () {
      final result = TodoTitle.create('   ');
      expect(result.isLeft(), isTrue);
      result.match(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('성공하면 안 된다'),
      );
    });

    test('최대 길이를 넘으면 ValidationFailure', () {
      final result = TodoTitle.create('가' * (TodoTitle.maxLength + 1));
      expect(result.isLeft(), isTrue);
    });

    test('같은 값이면 동등하다(값 객체)', () {
      final a = TodoTitle.create('메모').getOrElse((_) => TodoTitle.trusted('x'));
      final b = TodoTitle.create('메모').getOrElse((_) => TodoTitle.trusted('y'));
      expect(a, b);
    });
  });
}
