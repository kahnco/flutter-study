import 'package:flutter/widgets.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_bloc.dart';

/// bloc 을 서브트리에 내려 주는 InheritedWidget — flutter_bloc 의 `BlocProvider`
/// 를 직접 짠 것이다. [지하 탐사 3편]에서 판 `dependOnInheritedWidgetOfExactType`
/// 위에 얹어, 자식이 `TodosBlocProvider.of(context)` 로 bloc 을 집는다.
class TodosBlocProvider extends InheritedWidget {
  const TodosBlocProvider({
    super.key,
    required this.bloc,
    required super.child,
  });

  final TodosBloc bloc;

  static TodosBloc of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<TodosBlocProvider>();
    assert(provider != null, 'TodosBlocProvider 를 상위 트리에 두어야 합니다');
    return provider!.bloc;
  }

  // bloc 인스턴스가 그대로면 다시 알릴 필요가 없다.
  @override
  bool updateShouldNotify(TodosBlocProvider oldWidget) =>
      bloc != oldWidget.bloc;
}
