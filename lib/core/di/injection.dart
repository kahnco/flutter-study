import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_study/core/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

/// 의존성 그래프를 구성한다. 환경으로 실제(prod)/가짜(fake) 어댑터를 가른다.
/// prod 는 DB 를 여는 @preResolve 의존성이 있어 **비동기**다 — 반드시 await 한다.
///   await configureDependencies();                 // prod (sqflite)
///   await configureDependencies(environment: 'fake'); // 인메모리 테스트/데모
@InjectableInit()
Future<void> configureDependencies({String environment = 'prod'}) =>
    getIt.init(environment: environment);
