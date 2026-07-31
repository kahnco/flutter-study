import 'package:flutter_study/core/clock/clock.dart';
import 'package:flutter_study/core/di/injection.dart';
import 'package:flutter_study/core/id/id_generator.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => getIt.reset());

  test('fake 환경: 그래프 전체가 인메모리 어댑터로 해소된다', () async {
    await configureDependencies(environment: 'fake');

    expect(getIt<Clock>(), isA<FixedClock>());
    expect(getIt<IdGenerator>(), isA<SequentialIdGenerator>());
    expect(getIt.isRegistered<TodosRepository>(), isTrue);

    // 실제로 유스케이스를 끝까지 실행해 그래프가 살아있는지 확인
    final result = await getIt<AddTodo>()(TodoTitle.trusted('스모크'));
    expect(result.isRight(), isTrue);
  });
}
