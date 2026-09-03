import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_study/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';

/// todos 테이블 스키마. 모듈(생성 시)과 테스트가 같은 정의를 쓰도록 한곳에 둔다.
/// completed 는 SQLite 에 boolean 이 없어 0/1 정수로, created_at 은 epoch millis 로.
const String todosTable = 'todos';

/// 스키마 버전. v2 = keyset 인덱스(10편), v3 = 제목 전문 검색 FTS5(11편).
const int todosDbVersion = 3;

const String createTodosTableSql = '''
CREATE TABLE $todosTable(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  completed INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)
''';

/// keyset 정렬·커서 키 (created_at, id) 를 그대로 덮는 복합 인덱스.
/// 이게 있어야 `ORDER BY created_at, id` + `(created_at, id) > (?, ?)` 가 O(log n)(9편).
const String createTodosIndexSql =
    'CREATE INDEX IF NOT EXISTS idx_todos_created_at_id '
    'ON $todosTable(created_at, id)';

/// 제목 전문 검색용 FTS5 가상 테이블. external content(content='todos') 로
/// todos.title 을 색인만 하고 원본은 todos 에 둔다. rowid 로 둘을 잇는다(11편).
const String createTodosFtsSql = '''
CREATE VIRTUAL TABLE todos_fts USING fts5(
  title,
  content='todos',
  content_rowid='rowid'
)
''';

/// FTS 테이블 + todos 와 동기화하는 트리거를 만든다(external content 는 자동 동기화 안 됨).
Future<void> _createTodosFts(Database db) async {
  await db.execute(createTodosFtsSql);
  await db.execute('''
    CREATE TRIGGER todos_fts_ai AFTER INSERT ON $todosTable BEGIN
      INSERT INTO todos_fts(rowid, title) VALUES (new.rowid, new.title);
    END''');
  await db.execute('''
    CREATE TRIGGER todos_fts_ad AFTER DELETE ON $todosTable BEGIN
      INSERT INTO todos_fts(todos_fts, rowid, title) VALUES('delete', old.rowid, old.title);
    END''');
  await db.execute('''
    CREATE TRIGGER todos_fts_au AFTER UPDATE ON $todosTable BEGIN
      INSERT INTO todos_fts(todos_fts, rowid, title) VALUES('delete', old.rowid, old.title);
      INSERT INTO todos_fts(rowid, title) VALUES (new.rowid, new.title);
    END''');
}

/// 새 DB 생성(현재 버전): 테이블 + keyset 인덱스 + FTS.
Future<void> onCreateTodosDb(Database db, int version) async {
  await db.execute(createTodosTableSql);
  await db.execute(createTodosIndexSql);
  await _createTodosFts(db);
}

/// 스키마 업그레이드. 낮은 버전에서 올라올 때 필요한 변경만 **순서대로** 쌓아 적용한다.
/// v1 → v2: keyset 인덱스. v2 → v3: FTS 생성 후 기존 행을 백필.
Future<void> onUpgradeTodosDb(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute(createTodosIndexSql);
  }
  if (oldVersion < 3) {
    await _createTodosFts(db);
    await db.execute(
      'INSERT INTO todos_fts(rowid, title) SELECT rowid, title FROM $todosTable',
    );
  }
}

/// 사용자 입력을 FTS5 **접두** 질의로 바꾼다: 공백으로 나눠 각 토큰을 `"..."*` (암묵 AND).
/// 예: "우유 데우기" → `"우유"* "데우기"*`. 큰따옴표는 제거해 구문이 깨지지 않게 한다.
String _ftsQuery(String text) => text
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .map((t) => '"${t.replaceAll('"', '')}"*')
    .join(' ');

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
  Future<List<TodoModel>> search(TodoQuery query) async {
    // 필터·검색을 메모리가 아니라 SQL WHERE/LIKE 로 내린다(7편).
    final clauses = <String>[];
    final args = <Object?>[];

    switch (query.status) {
      case TodosFilter.active:
        clauses.add('completed = 0');
      case TodosFilter.completed:
        clauses.add('completed = 1');
      case TodosFilter.all:
        break;
    }

    final text = query.text.trim();
    if (text.isNotEmpty) {
      // LIKE 대신 FTS5 MATCH — 색인된 전문 검색으로(11편). 매칭된 rowid 만 추린다.
      clauses.add(
        'rowid IN (SELECT rowid FROM todos_fts WHERE todos_fts MATCH ?)',
      );
      args.add(_ftsQuery(text));
    }

    // keyset 커서: "마지막 본 항목 이후"만. 정렬 키와 같은 (created_at, id) 로 비교(9편).
    // SQLite 의 행 값(row value) 비교로 한 줄에 담는다.
    if (query.after case final cursor?) {
      clauses.add('(created_at, id) > (?, ?)');
      args
        ..add(cursor.createdAtMillis)
        ..add(cursor.id);
    }

    final rows = await _db.query(
      todosTable,
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at ASC, id ASC',
      limit: query.limit,
    );
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
