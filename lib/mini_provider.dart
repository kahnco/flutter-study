// 미니 Provider — package:provider 의 알맹이를 40줄로 직접 구현한다.
//
// 세 조각이면 상태관리가 된다:
//   1) Store        : 값이 바뀌면 알리는 관찰 가능 객체(= ChangeNotifier)
//   2) Provide       : store 를 트리에 내려주고, 알림이 오면 InheritedWidget 을 새로 세운다
//   3) watch / read  : context 확장 — 각각 dependOn(구독) / getInherited(비구독)
//
// 핵심은 3편의 주제 — watch 와 read 의 유일한 차이는 프레임워크 메서드 하나다:
//   watch → dependOnInheritedWidgetOfExactType (구독 → 값 바뀌면 이 위젯 리빌드)
//   read  → getInheritedWidgetOfExactType      (구독 안 함 → 콜백에서 안전하게 호출)

import 'package:flutter/widgets.dart';

/// 관찰 가능한 상태 홀더. 사용자는 이걸 상속해 자기 모델을 만들고,
/// 값을 바꾼 뒤 notifyListeners() 를 부른다. (ChangeNotifier 가 listener 관리를 해준다.)
abstract class Store extends ChangeNotifier {}

/// store 를 만들어 자손에게 내려준다. store 가 알림을 보낼 때마다 setState 로
/// 리빌드해, 안의 InheritedWidget(_Scope)을 새 버전으로 갈아 세운다.
class Provide<T extends Store> extends StatefulWidget {
  const Provide({super.key, required this.create, required this.child});

  final T Function() create;
  final Widget child;

  @override
  State<Provide<T>> createState() => _ProvideState<T>();
}

class _ProvideState<T extends Store> extends State<Provide<T>> {
  late final T _store = widget.create();
  int _version = 0; // 알림마다 증가 → updateShouldNotify 가 true 가 되게 하는 스냅샷

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _store.dispose();
    super.dispose();
  }

  void _onChange() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    // child 는 widget.child(부모가 한 번 준 동일 인스턴스) → 구조적 리빌드가 안 일어난다(2편).
    // 리빌드되는 건 오직 _Scope 를 구독한(watch 한) 자손뿐이다.
    return _Scope<T>(store: _store, version: _version, child: widget.child);
  }
}

/// 자손이 타입으로 찾아 구독하는 InheritedWidget. version 이 바뀌면 구독자에게 통지한다.
class _Scope<T extends Store> extends InheritedWidget {
  const _Scope({required this.store, required this.version, required super.child});

  final T store;
  final int version;

  @override
  bool updateShouldNotify(_Scope<T> oldWidget) => oldWidget.version != version;
}

/// `context.watch` / `context.read` — 이 두 개가 미니 Provider 의 공개 API.
extension StoreContext on BuildContext {
  /// watch: 구독한다. store 가 알리면 이 위젯이 리빌드된다. build 안에서 쓴다.
  T watch<T extends Store>() {
    final scope = dependOnInheritedWidgetOfExactType<_Scope<T>>();
    assert(scope != null, 'Provide<$T> 를 조상에 두세요');
    return scope!.store;
  }

  /// read: 구독하지 않는다. onPressed 같은 콜백에서 안전하게 store 를 꺼낼 때 쓴다.
  T read<T extends Store>() {
    final scope = getInheritedWidgetOfExactType<_Scope<T>>();
    assert(scope != null, 'Provide<$T> 를 조상에 두세요');
    return scope!.store;
  }
}
