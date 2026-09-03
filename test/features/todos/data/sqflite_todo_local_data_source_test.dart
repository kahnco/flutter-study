// 실제 sqflite 어댑터 테스트 — ffi 로 인메모리 SQLite 를 열어 SQL 이 제대로
// 도는지 본다. 앱의 prod 경로와 같은 코드(insert/update/delete/readAll)를 태운다.
import 'package:flutter_study/features/todos/data/datasources/sqflite_todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqfliteTodoLocalDataSource ds;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: todosDbVersion,
        onCreate: onCreateTodosDb,
        onUpgrade: onUpgradeTodosDb,
      ),
    );
    ds = SqfliteTodoLocalDataSource(db);
  });

  tearDown(() => db.close());

  TodoModel model(String id, {bool completed = false, int at = 0}) => TodoModel(
        id: id,
        title: '할 일 $id',
        completed: completed,
        createdAtMillis: at,
      );

  test('insert 한 행을 readAll 로 되읽는다', () async {
    await ds.insert(model('id-1'));
    final all = await ds.readAll();
    expect(all.single.id, 'id-1');
    expect(all.single.title, '할 일 id-1');
  });

  test('created_at 오름차순으로 정렬해 돌려준다', () async {
    await ds.insert(model('id-2', at: 200));
    await ds.insert(model('id-1', at: 100));
    final all = await ds.readAll();
    expect(all.map((m) => m.id).toList(), ['id-1', 'id-2']);
  });

  test('update 로 완료 상태가 반영된다', () async {
    await ds.insert(model('id-1'));
    await ds.update(model('id-1', completed: true));
    final all = await ds.readAll();
    expect(all.single.completed, isTrue);
  });

  test('delete 로 해당 행만 사라진다', () async {
    await ds.insert(model('id-1'));
    await ds.insert(model('id-2', at: 1));
    await ds.delete('id-1');
    final all = await ds.readAll();
    expect(all.map((m) => m.id).toList(), ['id-2']);
  });

  test('completed 는 컬럼에 0/1 정수로 저장된다', () async {
    await ds.insert(model('id-1', completed: true));
    final raw = await db.query(todosTable);
    expect(raw.single['completed'], 1);
  });

  // 제목을 지정해 넣는 헬퍼(검색 테스트용).
  TodoModel titled(String id, String title,
          {bool completed = false, int at = 0}) =>
      TodoModel(
          id: id, title: title, completed: completed, createdAtMillis: at);

  group('search — WHERE + FTS5 MATCH', () {
    test('status=active 는 completed=0 만 (WHERE)', () async {
      await ds.insert(titled('1', '가', completed: true));
      await ds.insert(titled('2', '나'));
      final rows = await ds.search(const TodoQuery(status: TodosFilter.active));
      expect(rows.map((m) => m.id).toList(), ['2']);
    });

    test('FTS 접두 MATCH 로 토큰을 찾는다', () async {
      await ds.insert(titled('1', '우유 사기'));
      await ds.insert(titled('2', '청소하기'));
      await ds.insert(titled('3', '우유 데우기'));
      final rows = await ds.search(const TodoQuery(text: '우유'));
      expect(rows.map((m) => m.id).toList(), ['1', '3']);
    });

    test('필터와 검색어는 AND 로 함께 적용된다', () async {
      await ds.insert(titled('1', '우유 사기', completed: true));
      await ds.insert(titled('2', '우유 데우기'));
      final rows = await ds.search(
        const TodoQuery(status: TodosFilter.active, text: '우유'),
      );
      expect(rows.map((m) => m.id).toList(), ['2']);
    });

    test('여러 단어는 AND 로 좁힌다', () async {
      await ds.insert(titled('1', '우유 사기'));
      await ds.insert(titled('2', '우유 데우기'));
      // "우유 데우기" → 두 토큰 모두 가진 것만.
      final rows = await ds.search(const TodoQuery(text: '우유 데우'));
      expect(rows.map((m) => m.id).toList(), ['2']);
    });

    test('업데이트하면 검색 색인도 따라 바뀐다(트리거 동기화)', () async {
      await ds.insert(titled('1', '우유 사기'));
      // 제목을 바꾸면 트리거가 FTS 를 갱신 → 옛 토큰으론 안 잡히고 새 토큰으로 잡힌다.
      await ds.update(titled('1', '커피 사기'));
      expect(await ds.search(const TodoQuery(text: '우유')), isEmpty);
      expect((await ds.search(const TodoQuery(text: '커피'))).single.id, '1');
    });

    test('keyset 커서로 페이지를 끊어 온다', () async {
      for (var i = 1; i <= 5; i++) {
        await ds.insert(titled('$i', '할 일 $i', at: i));
      }
      // 첫 페이지: 커서 없음
      final page1 = await ds.search(const TodoQuery(limit: 2));
      expect(page1.map((m) => m.id).toList(), ['1', '2']);
      // 다음 페이지: 마지막 항목(2)을 커서로
      final page2 = await ds.search(
        TodoQuery(limit: 2, after: TodoCursor(createdAtMillis: 2, id: '2')),
      );
      expect(page2.map((m) => m.id).toList(), ['3', '4']);
      final page3 = await ds.search(
        TodoQuery(limit: 2, after: TodoCursor(createdAtMillis: 4, id: '4')),
      );
      expect(page3.map((m) => m.id).toList(), ['5']);
    });

    test('keyset 은 페이지 사이 삭제에도 항목을 건너뛰지 않는다', () async {
      for (var i = 1; i <= 5; i++) {
        await ds.insert(titled('$i', '할 일 $i', at: i));
      }
      final page1 = await ds.search(const TodoQuery(limit: 2)); // [1,2]
      expect(page1.map((m) => m.id).toList(), ['1', '2']);

      // 페이지 사이에 앞쪽 항목(1)을 삭제 — offset(2)이었다면 3을 건너뛰었을 상황.
      await ds.delete('1');

      // 커서(2) 이후를 청하므로 3을 안 건너뛴다.
      final page2 = await ds.search(
        TodoQuery(limit: 2, after: TodoCursor(createdAtMillis: 2, id: '2')),
      );
      expect(page2.map((m) => m.id).toList(), ['3', '4']);
    });
  });

  group('마이그레이션 (스키마 버전 올리기)', () {
    // todos 테이블에 걸린 우리 인덱스 이름 목록(PK 자동 인덱스는 이름이 달라 구분됨).
    Future<List<String>> indexNames(Database d) async {
      final rows = await d.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [todosTable],
      );
      return rows.map((r) => r['name'] as String).toList();
    }

    test('v1 DB 를 최신으로 열면 인덱스·FTS 가 생기고 데이터·검색이 살아난다', () async {
      final path = p.join(
        await getDatabasesPath(),
        'migrate_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      addTearDown(() => databaseFactory.deleteDatabase(path));

      // 1) v1(테이블만, 인덱스·FTS 없음)으로 열어 데이터 저장 후 닫기.
      final v1 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute(createTodosTableSql),
        ),
      );
      await v1.insert(todosTable, {
        'id': 'id-1',
        'title': '옛 우유 데이터',
        'completed': 0,
        'created_at': 0,
      });
      expect(await indexNames(v1), isNot(contains('idx_todos_created_at_id')));
      await v1.close();

      // 2) 최신 버전으로 재오픈 → onUpgrade 로 인덱스 + FTS(백필).
      final upgraded = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: todosDbVersion,
          onCreate: onCreateTodosDb,
          onUpgrade: onUpgradeTodosDb,
        ),
      );
      expect(await indexNames(upgraded), contains('idx_todos_created_at_id'));
      expect((await upgraded.query(todosTable)).single['title'], '옛 우유 데이터');

      // 백필된 행이 FTS 검색으로 잡혀야 한다(마이그레이션이 검색까지 살렸는지).
      final ds2 = SqfliteTodoLocalDataSource(upgraded);
      final found = await ds2.search(const TodoQuery(text: '우유'));
      expect(found.single.id, 'id-1');
      await upgraded.close();
    });

    test('새 v2 DB 는 onCreate 로 처음부터 인덱스를 갖는다', () async {
      final fresh = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: todosDbVersion,
          onCreate: onCreateTodosDb,
        ),
      );
      expect(await indexNames(fresh), contains('idx_todos_created_at_id'));
      await fresh.close();
    });
  });
}
