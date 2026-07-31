import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';

/// todos 테이블 스키마. 모듈(생성 시)과 테스트가 같은 정의를 쓰도록 한곳에 둔다.
/// completed 는 SQLite 에 boolean 이 없어 0/1 정수로, created_at 은 epoch millis 로.
const String todosTable = 'todos';
const String createTodosTableSql = '''
CREATE TABLE $todosTable(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  completed INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)
''';

/// 실제 영속(prod) 어댑터. sqflite 로 디스크에 남긴다 — 앱을 꺼도 살아있다.
/// [Database] 는 주입받는다(열기는 DatabaseModule 이 @preResolve 로 담당).
/// 덕분에 이 클래스는 플러그인을 몰라, 테스트에서 ffi 로 연 DB 를 그대로 물릴 수 있다.
@LazySingleton(as: TodoLocalDataSource, env: ['prod'])
class SqfliteTodoLocalDataSource implements TodoLocalDataSource {
  const SqfliteTodoLocalDataSource(this._db);

  final Database _db;

  @override
  Future<List<TodoModel>> readAll() async {
    // 삽입 순서를 유지하려 created_at 동률이면 rowid 로 갈음한다.
    final rows = await _db.query(todosTable, orderBy: 'created_at ASC, rowid ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(TodoModel todo) => _db.insert(
        todosTable,
        _toRow(todo),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> update(TodoModel todo) => _db.update(
        todosTable,
        _toRow(todo),
        where: 'id = ?',
        whereArgs: [todo.id],
      );

  @override
  Future<void> delete(String id) =>
      _db.delete(todosTable, where: 'id = ?', whereArgs: [id]);

  Map<String, Object?> _toRow(TodoModel t) => {
        'id': t.id,
        'title': t.title,
        'completed': t.completed ? 1 : 0,
        'created_at': t.createdAtMillis,
      };

  TodoModel _fromRow(Map<String, Object?> r) => TodoModel(
        id: r['id']! as String,
        title: r['title']! as String,
        completed: (r['completed']! as int) == 1,
        createdAtMillis: r['created_at']! as int,
      );
}
