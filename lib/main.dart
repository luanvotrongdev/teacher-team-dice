import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/class_form/class_form_screen.dart';
import 'features/draw/draw_screen.dart';
import 'features/saved/class_detail_screen.dart';
import 'features/saved/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: TeamDiceApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/new', builder: (_, _) => const ClassFormScreen()),
    GoRoute(
      path: '/draw/:id',
      builder: (_, s) => DrawScreen(classId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/class/:id',
      builder: (_, s) => ClassDetailScreen(classId: int.parse(s.pathParameters['id']!)),
    ),
  ],
);

class TeamDiceApp extends StatelessWidget {
  const TeamDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Team Dice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: _router,
    );
  }
}
