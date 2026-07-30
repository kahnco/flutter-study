# BuildContext 지하 탐사

> 증명 코드: [`test/buildcontext_deep_test.dart`](../test/buildcontext_deep_test.dart) — `fvm flutter test`
> 프레임워크 소스: `package:flutter/src/widgets/framework.dart` (Element, BuildOwner, InheritedElement)

## 한 줄 요약

**BuildContext 는 별도의 무엇이 아니라 `Element` 그 자체다.** `Element` 가 `BuildContext`
인터페이스를 구현한다. `build(BuildContext context)` 의 `context` 는 그 위젯 자리의 `Element`다.
즉 BuildContext = **살아있는 Element 트리에서 "내 위치"를 가리키는 핸들**.

## 세 그루의 나무

| 트리 | 정체 | 수명 | 역할 |
|---|---|---|---|
| **Widget** | 불변 설정(청사진) | 짧음 — 매 빌드마다 새로 생성·폐기 | "무엇을 그릴지" 기술 |
| **Element** | 살아있는 런타임 노드 = **BuildContext** | 긺 — 같은 자리면 유지 | 위젯↔렌더 연결, 부모/자식·의존성·수명 관리 |
| **RenderObject** | 레이아웃·페인트·히트테스트 | 긺 | 실제 크기 계산·픽셀 |

- Widget 은 `@immutable`. `setState` 는 위젯을 바꾸지 않는다 — 새 위젯을 만들어 **같은 Element 에
  갈아끼운다**. (test 2: Element 는 identical, Widget 은 매번 교체)
- 그래서 "context 를 State 필드처럼 들고 재사용"이 성립한다 — 자리가 그대로면 Element 가 그대로다.

## Element 의 속살 (framework.dart)

```
abstract class Element implements BuildContext {
  Element? _parent;              // 부모(위로 걷는 사슬)
  Object? _slot;                 // 부모의 자식 목록에서 내 위치
  int _depth;                    // 루트로부터 깊이(리빌드 순서 정렬 키)
  BuildOwner? _owner;            // 더티 목록·빌드 스코프의 주인(트리 전체가 공유)
  _ElementLifecycle _lifecycleState; // initial → active → inactive → defunct
  Widget? _widget;               // 이 자리의 현재 위젯
  Set<InheritedElement>? _dependencies;          // 내가 구독한 InheritedElement 들
  PersistentHashMap<Type, InheritedElement> _inheritedElements; // 조상 Inherited 색인
}
```

- **수명주기**: `mount`(트리에 붙음) → `update`(새 위젯으로 갱신) → `deactivate`/`activate`
  (GlobalKey 이동 등) → `unmount`(제거, defunct). (test 5: 제거되면 `context.mounted == false`)
- `mounted` 는 `_lifecycleState == active`. **async gap 뒤 context 를 쓰면 안 되는 이유** —
  await 사이에 프레임이 지나 Element 가 죽었을 수 있다.

## 리빌드는 어떻게 도는가 — BuildOwner + 더티 목록

`setState` 는 마법이 아니다. 흐름은 전부 **동기·단일 스레드**다.

```
setState()
  → Element.markNeedsBuild()        // _dirty = true
  → owner.scheduleBuildFor(this)    // owner._dirtyElements 에 추가
  → SchedulerBinding.ensureVisualUpdate()  // 다음 프레임 요청

다음 프레임(VSync):
  WidgetsBinding.drawFrame
  → buildOwner.buildScope(rootElement)
      → _dirtyElements 를 depth 오름차순 정렬(얕은 것 먼저)
      → 각 element.rebuild() → performRebuild() → build() → updateChild()
  → (이후) flushLayout → flushPaint → 레이어 트리 합성
```

- 더티 목록을 **깊이 순**으로 도는 이유: 부모를 먼저 리빌드하면 자식은 그 과정에서 갱신되니
  중복을 피한다.
- `updateChild(oldElement, newWidget, slot)` 가 4트리 재조정(reconciliation)의 심장:
  - `newWidget == oldWidget`(identical) → 자식 리빌드 **생략**. (test 4 가 이걸 이용)
  - `Widget.canUpdate`(runtimeType + key 동일) → 제자리 `update`.
  - 아니면 옛 Element `unmount` + 새 Element `mount`(=교체).

## InheritedWidget — context 가 상태를 "구독"하는 진짜 메커니즘

`Provider`, `Theme.of`, `MediaQuery.of` 가 전부 이 위에 있다.

1. **색인(O(1) 조회)**: Element 가 mount 될 때 부모의 `_inheritedElements`(불변 해시맵)를
   물려받는다. 자신이 `InheritedElement` 면 거기에 자기를 얹는다. → 아무리 깊어도
   `dependOnInheritedWidgetOfExactType<T>()` 는 **맵 조회 O(1)**. (test 4-2: 50겹 아래서도 즉시)
2. **구독**: `dependOn...` 은 조회만 하지 않는다 —
   - 그 `InheritedElement._dependents` 에 **나를 등록**하고,
   - 내 `_dependencies` 에 그 Inherited 를 담는다.
3. **통지**: InheritedWidget 이 새 값으로 교체되고 `updateShouldNotify == true` 면 →
   `InheritedElement.notifyClients()` → 등록된 **각 dependent 만** `markNeedsBuild`. →
   의존한 자손만 리빌드된다. (test 4-1: 의존 O 리빌드, 의존 X 안 됨)

> 구독 없는 조회도 있다: `findAncestorWidgetOfExactType` /
> `getElementForInheritedWidgetOfExactType` 는 등록을 안 한다(1회성, 값이 바뀌어도 통지 없음).
> `findAncestorStateOfType` 는 부모 사슬을 **O(깊이)** 로 걸어 올라가는 조회. (test 3)

## 지하 — 스레드·아이솔레이트

- Dart 코드(위젯·엘리먼트·렌더 트리, 빌드/레이아웃/페인트 파이프라인)는 전부 **UI(root)
  아이솔레이트의 단일 스레드**에서 돈다. 위젯 트리에는 멀티스레드가 없다.
- 엔진(C++)에는 platform/raster(GPU)/IO 스레드가 따로 있지만, **네 Dart 위젯 코드는 거기서
  절대 실행되지 않는다.** raster 스레드는 페인트가 만든 레이어 트리를 소비할 뿐 Element 를 안 만진다.
- **아이솔레이트는 메모리를 공유하지 않는다.** (test 6: 새 아이솔레이트는 메인의 값을 못 보고,
  메인도 영향 없음) → 그래서 `compute()`/`Isolate.run` 에 **BuildContext 를 넘길 수 없다.**
  무거운 일은 순수 데이터만 아이솔레이트로 보내고, 결과를 받아 **UI 아이솔레이트에서** context 를 만진다.
- `Future`/`await` 는 다른 스레드가 아니다 — **같은 아이솔레이트의 이벤트 루프**가 나중에 이어
  실행하는 것. 그래서 await 뒤에도 스레드는 그대로지만, 그 사이 프레임이 지나 Element 가 죽을 수
  있어 `context.mounted` 확인이 필요하다.

## 실무 규칙이 왜 그런가 (한 줄씩)

- **"async gap 뒤 context 금지"** → 그 사이 Element 가 unmount(defunct) 됐을 수 있다.
- **"of(context) 는 Provider 아래에서만"** → InheritedElement 가 조상이어야 `_inheritedElements`
  맵에 들어온다.
- **"context 마다 결과가 다르다"**(Theme.of 등) → context 는 전역이 아니라 **트리 위치**다.
- **"build 안에서 무거운 조회 반복 금지"** → InheritedWidget 조회는 O(1)이지만
  `findAncestorStateOfType` 류는 O(깊이). 자주 쓰면 캐시하거나 구조를 바꾼다.
