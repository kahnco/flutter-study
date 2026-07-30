import 'package:flutter/widgets.dart';
import 'package:flutter_study/core/di/injection.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_bloc.dart';
import 'package:flutter_study/features/todos/presentation/bloc/todos_event.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_bloc_provider.dart';

/// bloc 의 **수명**을 쥔 StatefulWidget. 여기서 만들고(getIt), 시작 이벤트를 던지고,
/// 화면이 사라질 때 dispose 로 StreamController 를 닫는다 — 손으로 짠 bloc 의
/// 폐기 책임이 이 한 곳에 모인다. 실제 bloc 전달은 [TodosBlocProvider] 가 맡는다.
class TodosScope extends StatefulWidget {
  const TodosScope({super.key, required this.child, this.bloc});

  final Widget child;

  /// 테스트에서 bloc 을 갈아 끼울 때만 준다. 평소엔 컨테이너에서 만든다.
  final TodosBloc? bloc;

  @override
  State<TodosScope> createState() => _TodosScopeState();
}

class _TodosScopeState extends State<TodosScope> {
  late final TodosBloc _bloc = widget.bloc ?? getIt<TodosBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(const TodosStarted());
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TodosBlocProvider(bloc: _bloc, child: widget.child);
}
