import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/usecase/usecase.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';

/// 할 일의 제목을 바꾼다. 입력은 (id, 검증된 제목) — 검증은 bloc 이 값 객체로 한다.
@lazySingleton
class EditTodo implements UseCase<Unit, (String, TodoTitle)> {
  const EditTodo(this._repo);
  final TodosRepository _repo;

  @override
  Future<Either<Failure, Unit>> call((String, TodoTitle) params) =>
      _repo.edit(params.$1, params.$2);
}
