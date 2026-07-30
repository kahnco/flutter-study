import 'package:flutter/material.dart';
import 'package:flutter_study/core/di/injection.dart';
import 'package:flutter_study/features/todos/presentation/pages/todos_page.dart';
import 'package:flutter_study/features/todos/presentation/widgets/todos_scope.dart';

void main() {
  configureDependencies(); // prod 그래프 조립(1편)
  runApp(const TodoApp());
}

/// 앱 루트. bloc 을 트리에 올리는 [TodosScope] 로 화면을 감싼다.
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할 일',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TodosScope(child: TodosPage()),
    );
  }
}
