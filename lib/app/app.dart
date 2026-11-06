import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'tool.dart';
import 'tools.dart';

/// Placeholder app name shown on the main menu; the platform display names
/// (iOS Info.plist, web/index.html + manifest.json, Windows Runner.rc) still say "Team Dice".
const appName = 'Teacher Tools';

class TeacherToolsApp extends StatefulWidget {
  const TeacherToolsApp({super.key, this.tools});

  /// Defaults to [appTools]; tests can pass their own list.
  final List<ToolDefinition>? tools;

  @override
  State<TeacherToolsApp> createState() => _TeacherToolsAppState();
}

class _TeacherToolsAppState extends State<TeacherToolsApp> {
  late final GoRouter _router = buildRouter(widget.tools ?? appTools);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: _router,
      // In landscape on a phone, keep every screen clear of the notch and rounded corners.
      // App bars and bottom bars already pad the top and bottom themselves.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(top: false, bottom: false, child: child!),
      ),
    );
  }
}
