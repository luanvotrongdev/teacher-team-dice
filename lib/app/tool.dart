import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Describes one tool shown in the main menu.
///
/// A tool lives under `lib/tools/<name>/` and owns its screens, logic and tables.
/// It gets mounted at `/<id>`; its own [routes] are relative to that path.
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.home,
    this.routes = const [],
  });

  /// Stable, URL-safe id (e.g. `team-dice`). Also the tool's route segment.
  final String id;
  final String name;

  /// One line shown under the name in the main menu.
  final String description;
  final IconData icon;

  /// The tool's start screen.
  final WidgetBuilder home;

  /// Sub-routes, relative to `/<id>` (e.g. `GoRoute(path: 'new', ...)`).
  final List<RouteBase> routes;

  String get path => '/$id';

  GoRoute toRoute() => GoRoute(path: id, builder: (context, _) => home(context), routes: routes);
}
