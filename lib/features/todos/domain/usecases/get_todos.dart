import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/usecase/usecase.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';

/// 조건에 맞는 할 일을 읽는다. 조건([TodoQuery])은 필터·검색어를 담는다.
@lazySingleton
class GetTodos implements UseCase<List<Todo>, TodoQuery> {
  const GetTodos(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, List<Todo>>> call(TodoQuery params) =>
      _repo.search(params);
}
