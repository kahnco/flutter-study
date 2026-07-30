import 'package:flutter_study/features/todos/domain/entities/todo.dart';
import 'package:flutter_study/features/todos/domain/value_objects/todo_title.dart';

/// 저장소 표현(직렬화 가능). 도메인 Todo 와 JSON 사이를 오간다.
class TodoModel {
  const TodoModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAtMillis,
  });

  final String id;
  final String title;
  final bool completed;
  final int createdAtMillis;

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
        id: json['id'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool,
        createdAtMillis: json['createdAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'createdAt': createdAtMillis,
      };

  factory TodoModel.fromDomain(Todo todo) => TodoModel(
        id: todo.id,
        title: todo.title.value,
        completed: todo.completed,
        createdAtMillis: todo.createdAt.millisecondsSinceEpoch,
      );

  Todo toDomain() => Todo(
        id: id,
        title: TodoTitle.trusted(title),
        completed: completed,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      );

  TodoModel copyWith({bool? completed}) => TodoModel(
        id: id,
        title: title,
        completed: completed ?? this.completed,
        createdAtMillis: createdAtMillis,
      );
}
