import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_study/features/todos/data/datasources/sqflite_todo_local_data_source.dart';

/// 열려 있는 [Database] 를 그래프에 공급한다. DB 열기는 **비동기**라,
/// @preResolve 로 앱 시작 시 미리 열어 둔다(그래서 configureDependencies 가 async).
/// prod 환경에만 등록 — fake(인메모리)는 DB 를 열지 않는다.
@module
abstract class DatabaseModule {
  @preResolve
  @Environment('prod')
  Future<Database> database() async {
    final path = p.join(await getDatabasesPath(), 'todos.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute(createTodosTableSql),
    );
  }
}
