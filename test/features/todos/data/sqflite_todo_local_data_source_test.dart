// 실제 sqflite 어댑터 테스트 — ffi 로 인메모리 SQLite 를 열어 SQL 이 제대로
// 도는지 본다. 앱의 prod 경로와 같은 코드(insert/update/delete/readAll)를 태운다.
import 'package:flutter_study/features/todos/data/datasources/sqflite_todo_local_data_source.dart';
import 'package:flutter_study/features/todos/data/models/todo_model.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_query.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todos_filter.dart';
import 'package:flutter_test/flutter_test.dart';
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
        version: 1,
        onCreate: (db, version) => db.execute(createTodosTableSql),
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
  TodoModel titled(String id, String title, {bool completed = false}) =>
      TodoModel(
          id: id, title: title, completed: completed, createdAtMillis: 0);

  group('search — SQL WHERE/LIKE', () {
    test('status=active 는 completed=0 만 (WHERE)', () async {
      await ds.insert(titled('1', '가', completed: true));
      await ds.insert(titled('2', '나'));
      final rows = await ds.search(const TodoQuery(status: TodosFilter.active));
      expect(rows.map((m) => m.id).toList(), ['2']);
    });

    test('제목 LIKE 로 부분 일치를 찾는다', () async {
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

    test('LIKE 와일드카드(%)는 리터럴로 이스케이프된다', () async {
      await ds.insert(titled('1', '50% 할인'));
      await ds.insert(titled('2', '무엇이든'));
      // '%' 를 와일드카드로 봤다면 둘 다 걸리지만, 이스케이프되므로 1건만.
      final rows = await ds.search(const TodoQuery(text: '%'));
      expect(rows.map((m) => m.id).toList(), ['1']);
    });
  });
}
