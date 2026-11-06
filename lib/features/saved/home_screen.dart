import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Team Dice')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/new');
          ref.invalidate(classListProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('New class'),
      ),
      body: classes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load classes: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No classes yet. Create one to get started.'));
          }
          return ListView.builder(
            // Extra bottom room so the last card isn't hidden behind the FAB / home indicator.
            padding: EdgeInsets.fromLTRB(16, 16, 16, 88 + MediaQuery.paddingOf(context).bottom),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text(
                    '${c.students.length} students · ${c.groups.length} groups · '
                    '${c.hasResult ? 'saved' : 'not drawn yet'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push(c.hasResult ? '/class/${c.id}' : '/draw/${c.id}');
                    ref.invalidate(classListProvider);
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
