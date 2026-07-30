import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/usecase/usecase.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';

@lazySingleton
class GetTodos implements UseCase<List<Todo>, NoParams> {
  const GetTodos(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) => _repo.getAll();
}
