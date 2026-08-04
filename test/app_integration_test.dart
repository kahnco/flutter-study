// 앱 전체 통합 테스트 — 실제 조립 루트(configureDependencies)로 prod 그래프를
// 그대로 세우고, 컨테이너가 내준 TodosBloc 을 이벤트로 구동해
// bloc → 유스케이스 → repository → sqflite → 실제 SQLite 파일까지 관통한다.
//
// 인메모리가 아니라 .dart_tool 아래 **파일** DB 를 쓴다. 그래서 그래프를 헐고
// 같은 파일로 다시 세우는 것으로 '앱 재시작'을 흉내 내, 데이터가 살아남는지까지 본다.
// (위젯 렌더링 계층은 widget_test.dart 가 fake 환경으로 따로 덮는다.)
import 'dart:io';

import 'package:flutter_study/core/di/injection.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi; // 앱의 openDatabase 를 ffi 로 돌린다
  });

  Future<String> dbFilePath() async =>
      p.join(await getDatabasesPath(), 'todos.db');

  Future<void> deleteDbFile() async {
    final file = File(await dbFilePath());
    if (file.existsSync()) file.deleteSync();
  }

  setUp(deleteDbFile); // 매 테스트 깨끗한 파일에서 시작
  tearDown(() async {
    if (getIt.isRegistered<Database>()) await getIt<Database>().close();
    await getIt.reset();
    await deleteDbFile();
  });

  /// 상태 스트림에서 [predicate] 를 만족하는 첫 TodosLoaded 를 기다린다.
  /// 구독을 먼저 걸어 두고 이벤트를 던지도록, 반드시 add 전에 호출한다.
  Future<TodosLoaded> nextLoaded(
    TodosBloc bloc,
    bool Function(TodosLoaded) predicate,
  ) =>
      bloc.stream
          .where((s) => s is TodosLoaded && predicate(s))
          .cast<TodosLoaded>()
          .first;

  test('실제 그래프로 부팅 — 추가·토글·삭제가 전 계층을 관통한다', () async {
    await configureDependencies(); // prod: 실제 DI + sqflite 파일 오픈
    final bloc = getIt<TodosBloc>();

    final started = nextLoaded(bloc, (s) => s.todos.isEmpty);
    bloc.add(const TodosStarted());
    await started;

    final added = nextLoaded(bloc, (s) => s.todos.length == 1);
    bloc.add(const TodoAdded('우유 사기'));
    final id = (await added).todos.single.id;
    expect((await added).todos.single.title.value, '우유 사기');

    final toggled = nextLoaded(bloc, (s) => s.todos.single.completed);
    bloc.add(TodoToggled(id));
    await toggled;

    final removed = nextLoaded(bloc, (s) => s.todos.isEmpty);
    bloc.add(TodoRemoved(id));
    await removed;

    await bloc.dispose();
  });

  test('앱을 재시작해도 SQLite 파일에 남아 다시 올라온다', () async {
    // 1) 첫 부팅 — 두 건 저장
    await configureDependencies();
    final bloc1 = getIt<TodosBloc>();
    final empty1 = nextLoaded(bloc1, (s) => s.todos.isEmpty);
    bloc1.add(const TodosStarted());
    await empty1;

    final one = nextLoaded(bloc1, (s) => s.todos.length == 1);
    bloc1.add(const TodoAdded('첫째 일'));
    await one;
    final two = nextLoaded(bloc1, (s) => s.todos.length == 2);
    bloc1.add(const TodoAdded('둘째 일'));
    await two;
    await bloc1.dispose();

    // 2) 재시작 — DB 닫고 그래프 비우기
    await getIt<Database>().close();
    await getIt.reset();

    // 3) 같은 파일로 재부팅 — 저장된 두 건이 다시 올라와야 한다
    await configureDependencies();
    final bloc2 = getIt<TodosBloc>();
    final reloaded = nextLoaded(bloc2, (s) => s.todos.length == 2);
    bloc2.add(const TodosStarted());
    final titles = (await reloaded).todos.map((t) => t.title.value).toList();
    expect(titles, containsAll(['첫째 일', '둘째 일']));
    await bloc2.dispose();
  });
}
