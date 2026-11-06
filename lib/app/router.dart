import 'package:go_router/go_router.dart';

import 'main_menu_screen.dart';
import 'tool.dart';

/// `/` is the main menu; each tool is nested under it at `/<id>`, so going back
/// from a tool's start screen always lands on the menu.
GoRouter buildRouter(List<ToolDefinition> tools) {
  assert(tools.map((t) => t.id).toSet().length == tools.length, 'Tool ids must be unique');
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MainMenuScreen(tools: tools),
        routes: [for (final tool in tools) tool.toRoute()],
      ),
    ],
  );
}
