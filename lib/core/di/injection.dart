import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter_study/core/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

/// 의존성 그래프를 구성한다. 환경으로 실제(prod)/가짜(fake) 어댑터를 가른다.
///   configureDependencies();                 // prod
///   configureDependencies(environment: 'fake'); // 인메모리 테스트/데모
@InjectableInit()
void configureDependencies({String environment = 'prod'}) =>
    getIt.init(environment: environment);
