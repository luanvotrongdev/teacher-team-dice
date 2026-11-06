import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/excel_service.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../routes.dart';

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});
  final int classId;

  Future<void> _export(BuildContext context, ClassModel c) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await FileSaver.instance.saveAs(
        name: '${c.name}_groups',
        bytes: buildExport(c),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      // Native save dialogs (iOS "Save to Files", Windows) return null when cancelled.
      if (path == null && !kIsWeb) return;
      messenger.showSnackBar(const SnackBar(content: Text('Exported to Excel')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ClassModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('"${c.name}" and its saved groups will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).deleteClass(c.id);
    // go() doesn't complete the list's `await push`, so refresh it here.
    ref.invalidate(classListProvider);
    if (context.mounted) context.go(TeamDiceRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(classProvider(classId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (c) {
        if (c == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Class not found')));
        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.go(TeamDiceRoutes.home)),
            title: Text(c.name),
            actions: [
              IconButton(
                tooltip: 'Re-roll',
                icon: const Icon(Icons.casino),
                onPressed: () async {
                  await context.push(TeamDiceRoutes.draw(c.id));
                  ref.invalidate(classProvider(classId));
                },
              ),
              IconButton(
                tooltip: 'Export Excel',
                icon: const Icon(Icons.table_view),
                onPressed: () => _export(context, c),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref, c),
              ),
            ],
          ),
          body: GroupsGrid(groups: c.groups),
        );
      },
    );
  }
}

class GroupsGrid extends StatelessWidget {
  const GroupsGrid({super.key, required this.groups});
  final List<GroupModel> groups;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 360,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final g = groups[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name, style: Theme.of(context).textTheme.titleMedium),
                if (g.project.isNotEmpty)
                  Text(g.project, style: Theme.of(context).textTheme.bodySmall),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      for (var k = 0; k < g.members.length; k++) Text('${k + 1}. ${g.members[k].name}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
