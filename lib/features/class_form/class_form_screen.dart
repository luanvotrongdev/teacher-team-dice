import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/excel_service.dart';
import '../../data/providers.dart';
import '../../models/models.dart';

class ClassFormScreen extends ConsumerStatefulWidget {
  const ClassFormScreen({super.key});

  @override
  ConsumerState<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends ConsumerState<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _countCtl = TextEditingController(text: '2');
  final _groupNames = <TextEditingController>[];
  final _projects = <TextEditingController>[];
  List<String> _students = [];
  String? _fileName;
  String? _fileError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resizeGroups(2);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _countCtl.dispose();
    for (final c in [..._groupNames, ..._projects]) {
      c.dispose();
    }
    super.dispose();
  }

  void _resizeGroups(int n) {
    while (_groupNames.length < n) {
      _groupNames.add(TextEditingController(text: 'Group ${_groupNames.length + 1}'));
      _projects.add(TextEditingController());
    }
    while (_groupNames.length > n) {
      _groupNames.removeLast().dispose();
      _projects.removeLast().dispose();
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (file == null) return;
      final names = parseStudents(await file.readAsBytes());
      setState(() {
        _students = names;
        _fileName = file.name;
        _fileError = null;
      });
    } on ExcelImportException catch (e) {
      setState(() {
        _students = [];
        _fileName = null;
        _fileError = e.message;
      });
    } catch (e) {
      setState(() => _fileError = 'Could not open file: $e');
    }
  }

  Future<void> _random() async {
    final fileOk = _students.isNotEmpty;
    if (!fileOk) setState(() => _fileError = 'Please import a student list (.xlsx).');
    if (!_formKey.currentState!.validate() || !fileOk) return;
    setState(() => _busy = true);
    try {
      final drafts = [
        for (var i = 0; i < _groupNames.length; i++)
          GroupDraft(
            name: _groupNames[i].text.trim().isEmpty ? 'Group ${i + 1}' : _groupNames[i].text.trim(),
            project: _projects[i].text.trim(),
          ),
      ];
      final id = await ref.read(repositoryProvider).createClass(_nameCtl.text.trim(), _students, drafts);
      if (mounted) context.pushReplacement('/draw/$id');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New class')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(labelText: 'Class name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Class name is required' : null,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import students (.xlsx)'),
                    ),
                    Text(
                      _students.isEmpty ? 'Names are read from column A' : '$_fileName — ${_students.length} students',
                    ),
                  ],
                ),
                if (_fileError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_fileError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Number of groups', border: OutlineInputBorder()),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Enter a number of at least 1';
                    if (_students.isNotEmpty && n > _students.length) {
                      return 'Cannot exceed number of students (${_students.length})';
                    }
                    return null;
                  },
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n >= 1 && n <= 100) setState(() => _resizeGroups(n));
                  },
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _groupNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _groupNames[i],
                            decoration: InputDecoration(labelText: 'Group ${i + 1} name', border: const OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _projects[i],
                            decoration: const InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _random,
                  icon: const Icon(Icons.casino),
                  label: const Padding(padding: EdgeInsets.all(12), child: Text('Random')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
