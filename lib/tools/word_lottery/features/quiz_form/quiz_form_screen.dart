import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/excel_import.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../routes.dart';

/// Creating a quiz: name it, import an .xlsx, then confirm what was read.
/// Nothing is saved until Confirm.
class QuizFormScreen extends ConsumerStatefulWidget {
  const QuizFormScreen({super.key});

  @override
  ConsumerState<QuizFormScreen> createState() => _QuizFormScreenState();
}

class _QuizFormScreenState extends ConsumerState<QuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  QuizDraft? _draft;
  String? _fileName;
  String? _fileError;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    try {
      final file = await ref.read(quizFilePickerProvider)();
      if (file == null) return;
      final draft = parseQuizSheet(file.bytes);
      setState(() {
        _draft = draft;
        _fileName = file.name;
        _fileError = null;
      });
    } on QuizImportException catch (e) {
      setState(() => _fileError = e.message);
    } catch (e) {
      setState(() => _fileError = 'Could not open file: $e');
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final id = await ref.read(quizRepositoryProvider).createQuiz(_nameCtl.text.trim(), _draft!.columns);
      // The list's own `await push` never returns once this screen is replaced, so refresh it here.
      ref.invalidate(quizListProvider);
      if (mounted) context.pushReplacement(WordLotteryRoutes.play(id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToForm() => setState(() => _draft = null);

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return PopScope(
      // Back on the confirmation step returns to the form instead of leaving.
      canPop: draft == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToForm();
      },
      child: draft == null ? _buildForm(context) : _buildConfirm(context, draft),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New quiz')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16) + EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextFormField(
                  controller: _nameCtl,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Quiz name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Quiz name is required' : null,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.upload_file),
                  label: const Padding(padding: EdgeInsets.all(12), child: Text('Import words (.xlsx)')),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use a file with one sheet. Each column is a list of words. '
                  'Empty rows and columns are removed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_fileError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_fileError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context, QuizDraft draft) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _backToForm),
        title: const Text('Confirm words'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_nameCtl.text.trim(), style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${draft.columns.length} columns · ${draft.wordCount} words · from $_fileName'),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 48,
                columnSpacing: 24,
                columns: [
                  for (var c = 0; c < draft.columns.length; c++)
                    DataColumn(label: Text('Column ${c + 1} (${draft.columns[c].length})')),
                ],
                rows: [
                  for (final r in draft.rows) DataRow(cells: [for (final cell in r) DataCell(Text(cell))]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _backToForm, child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _confirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
