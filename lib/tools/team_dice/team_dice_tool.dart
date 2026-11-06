import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/tool.dart';
import 'features/class_form/class_form_screen.dart';
import 'features/draw/draw_screen.dart';
import 'features/saved/class_detail_screen.dart';
import 'features/saved/home_screen.dart';

/// Team Dice: split a class into random, even groups. Paths live in routes.dart.
final teamDiceTool = ToolDefinition(
  id: 'team-dice',
  name: 'Team Dice',
  description: 'Split a class into random, even groups and hand out projects.',
  icon: Icons.casino,
  home: (_) => const TeamDiceHomeScreen(),
  routes: [
    GoRoute(path: 'new', builder: (_, _) => const ClassFormScreen()),
    GoRoute(
      path: 'draw/:id',
      builder: (_, s) => DrawScreen(classId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: 'class/:id',
      builder: (_, s) => ClassDetailScreen(classId: int.parse(s.pathParameters['id']!)),
    ),
  ],
);
