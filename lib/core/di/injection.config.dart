// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_study/core/clock/clock.dart' as _i405;
import 'package:flutter_study/core/database/database_module.dart' as _i464;
import 'package:flutter_study/core/id/id_generator.dart' as _i383;
import 'package:flutter_study/features/todos/data/datasources/sqflite_todo_local_data_source.dart'
    as _i15;
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart'
    as _i350;
import 'package:flutter_study/features/todos/data/repositories/todos_repository_impl.dart'
    as _i1060;
import 'package:flutter_study/features/todos/domain/repositories/todos_repository.dart'
    as _i58;
import 'package:flutter_study/features/todos/domain/usecases/add_todo.dart'
    as _i181;
import 'package:flutter_study/features/todos/domain/usecases/get_todos.dart'
    as _i819;
import 'package:flutter_study/features/todos/domain/usecases/remove_todo.dart'
    as _i502;
import 'package:flutter_study/features/todos/domain/usecases/toggle_todo.dart'
    as _i496;
import 'package:flutter_study/features/todos/presentation/bloc/todos_bloc.dart'
    as _i662;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sqflite/sqflite.dart' as _i779;

const String _prod = 'prod';
const String _fake = 'fake';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    gh.lazySingleton<_i405.Clock>(
      () => _i405.SystemClock(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i350.TodoLocalDataSource>(
      () => _i350.InMemoryTodoLocalDataSource(),
      registerFor: {_fake},
    );
    gh.lazySingleton<_i405.Clock>(
      () => _i405.FixedClock(),
      registerFor: {_fake},
    );
    await gh.factoryAsync<_i779.Database>(
      () => databaseModule.database(),
      registerFor: {_prod},
      preResolve: true,
    );
    gh.lazySingleton<_i383.IdGenerator>(
      () => _i383.TimeIdGenerator(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i383.IdGenerator>(
      () => _i383.SequentialIdGenerator(),
      registerFor: {_fake},
    );
    gh.lazySingleton<_i350.TodoLocalDataSource>(
      () => _i15.SqfliteTodoLocalDataSource(gh<_i779.Database>()),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i58.TodosRepository>(
      () => _i1060.TodosRepositoryImpl(
        gh<_i350.TodoLocalDataSource>(),
        gh<_i383.IdGenerator>(),
        gh<_i405.Clock>(),
      ),
    );
    gh.lazySingleton<_i181.AddTodo>(
      () => _i181.AddTodo(gh<_i58.TodosRepository>()),
    );
    gh.lazySingleton<_i819.GetTodos>(
      () => _i819.GetTodos(gh<_i58.TodosRepository>()),
    );
    gh.lazySingleton<_i502.RemoveTodo>(
      () => _i502.RemoveTodo(gh<_i58.TodosRepository>()),
    );
    gh.lazySingleton<_i496.ToggleTodo>(
      () => _i496.ToggleTodo(gh<_i58.TodosRepository>()),
    );
    gh.factory<_i662.TodosBloc>(
      () => _i662.TodosBloc(
        gh<_i819.GetTodos>(),
        gh<_i181.AddTodo>(),
        gh<_i496.ToggleTodo>(),
        gh<_i502.RemoveTodo>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i464.DatabaseModule {}
