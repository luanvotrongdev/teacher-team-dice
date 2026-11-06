import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/tool.dart';
import 'features/play/play_screen.dart';
import 'features/quiz_form/quiz_form_screen.dart';
import 'features/saved/home_screen.dart';

/// Word Lottery: import columns of words, then draw one random word from each column.
/// Paths live in routes.dart.
final wordLotteryTool = ToolDefinition(
  id: 'word-lottery',
  name: 'Word Lottery',
  description: 'Import columns of words and draw a random combination.',
  icon: Icons.local_activity,
  home: (_) => const WordLotteryHomeScreen(),
  routes: [
    GoRoute(path: 'new', builder: (_, _) => const QuizFormScreen()),
    GoRoute(
      path: 'quiz/:id',
      builder: (_, s) => PlayScreen(quizId: int.parse(s.pathParameters['id']!)),
    ),
  ],
);
