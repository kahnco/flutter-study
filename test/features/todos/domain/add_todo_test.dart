import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TodosRepository {}

void main() {
  late _MockRepo repo;
  late AddTodo usecase;
  final title = TodoTitle.trusted('할 일');

  setUp(() {
    repo = _MockRepo();
    usecase = AddTodo(repo);
  });

  test('repository.add 로 그대로 위임한다', () async {
    final todo = Todo(
      id: 'id-1',
      title: title,
      completed: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    when(() => repo.add(title)).thenAnswer((_) async => right(todo));

    final result = await usecase(title);

    expect(result.getOrElse((_) => throw StateError('right 여야')), todo);
    verify(() => repo.add(title)).called(1);
  });

  test('repository 실패를 그대로 전달한다', () async {
    when(() => repo.add(title))
        .thenAnswer((_) async => left(const CacheFailure()));

    final result = await usecase(title);

    expect(result.isLeft(), isTrue);
  });
}
