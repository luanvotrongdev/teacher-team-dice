import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../routes.dart';

class WordLotteryHomeScreen extends ConsumerWidget {
  const WordLotteryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(quizListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Word Lottery')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(WordLotteryRoutes.newQuiz);
          ref.invalidate(quizListProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('New quiz'),
      ),
      body: quizzes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load quizzes: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No quizzes yet. Create one to get started.'));
          }
          return ListView.builder(
            // Extra bottom room so the last card isn't hidden behind the FAB / home indicator.
            padding: EdgeInsets.fromLTRB(16, 16, 16, 88 + MediaQuery.paddingOf(context).bottom),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final q = list[i];
              return Card(
                child: ListTile(
                  title: Text(q.name),
                  subtitle: Text('${q.columns.length} columns · ${q.wordCount} words'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push(WordLotteryRoutes.play(q.id));
                    ref.invalidate(quizListProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
