import 'package:fpdart/fpdart.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';

/// 할 일 저장소 계약. 도메인이 소유하는 인터페이스(data 계층이 구현).
/// 모든 반환은 [Either] — 실패는 예외가 아니라 [Failure] 로 흐른다.
abstract interface class TodosRepository {
  Future<Either<Failure, List<Todo>>> getAll();
  Future<Either<Failure, Todo>> add(TodoTitle title);
  Future<Either<Failure, Unit>> toggle(String id);
  Future<Either<Failure, Unit>> remove(String id);
}
