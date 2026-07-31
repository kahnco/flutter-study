import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_study/core/clock/clock.dart';
import 'package:flutter_study/core/error/failure.dart';
import 'package:flutter_study/core/id/id_generator.dart';
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';

/// 도메인 계약을 로컬 저장소로 실현한다.
/// 경계에서 예외를 잡아 [Failure] 로 접는다 — 위 계층은 예외를 모른다.
/// 시간·id 는 주입받은 [Clock]·[IdGenerator] 로만 얻어 테스트에서 결정적이다.
@LazySingleton(as: TodosRepository)
class TodosRepositoryImpl implements TodosRepository {
  const TodosRepositoryImpl(this._local, this._ids, this._clock);

  final TodoLocalDataSource _local;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  Future<Either<Failure, List<Todo>>> getAll() async {
    try {
      final models = await _local.readAll();
      return right(models.map((m) => m.toDomain()).toList());
    } catch (_) {
      return left(const CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo>> add(TodoTitle title) async {
    try {
      final todo = Todo(
        id: _ids.next(),
        title: title,
        completed: false,
        createdAt: _clock.now(),
      );
      await _local.insert(TodoModel.fromDomain(todo));
      return right(todo);
    } catch (_) {
      return left(const CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> toggle(String id) async {
    try {
      final matches = (await _local.readAll()).where((m) => m.id == id);
      if (matches.isEmpty) return left(const CacheFailure('없는 항목입니다'));
      final target = matches.first;
      await _local.update(target.copyWith(completed: !target.completed));
      return right(unit);
    } catch (_) {
      return left(const CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> remove(String id) async {
    try {
      await _local.delete(id);
      return right(unit);
    } catch (_) {
      return left(const CacheFailure());
    }
  }
}
