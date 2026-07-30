import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/usecase/usecase.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';

@lazySingleton
class ToggleTodo implements UseCase<Unit, String> {
  const ToggleTodo(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String params) => _repo.toggle(params);
}
