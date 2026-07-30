import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/usecase/usecase.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';

@lazySingleton
class AddTodo implements UseCase<Todo, TodoTitle> {
  const AddTodo(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, Todo>> call(TodoTitle params) => _repo.add(params);
}
