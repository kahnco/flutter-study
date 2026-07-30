import 'package:equatable/equatable.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';

/// 할 일 도메인 엔티티. 순수 Dart — Flutter/저장소 타입에 의존하지 않는다.
class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
  });

  final String id;
  final TodoTitle title;
  final bool completed;
  final DateTime createdAt;

  Todo copyWith({TodoTitle? title, bool? completed}) => Todo(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, title, completed, createdAt];
}
