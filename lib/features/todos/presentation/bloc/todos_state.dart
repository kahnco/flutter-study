import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/entities/todo.dart';

/// bloc 에서 나오는 출력. 화면이 그릴 수 있는 **완결된** 한 장면.
sealed class TodosState extends Equatable {
  const TodosState();

  @override
  List<Object?> get props => [];
}

/// 아직 아무것도 불러오지 않은 최초 상태.
class TodosInitial extends TodosState {
  const TodosInitial();
}

/// 목록을 불러오는 중.
class TodosLoading extends TodosState {
  const TodosLoading();
}

/// 목록이 준비된 상태. [error] 는 방금 동작이 어긋났을 때만 실리는 **일시적** 메시지다
/// (검증 실패나 저장 실패 — 목록은 그대로 두고 화면에 한 줄만 띄우려는 것).
/// 다음 성공 상태에서 자연히 사라진다.
class TodosLoaded extends TodosState {
  const TodosLoaded(this.todos, {this.error});
  final List<Todo> todos;
  final String? error;

  TodosLoaded copyWith({List<Todo>? todos, String? error}) =>
      TodosLoaded(todos ?? this.todos, error: error);

  @override
  List<Object?> get props => [todos, error];
}

/// 목록 자체를 불러오지 못한, 화면 전체가 실패인 상태.
class TodosFailure extends TodosState {
  const TodosFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
