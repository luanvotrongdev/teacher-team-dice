# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Team Dice: a Flutter app for iOS (primary target, iPhone in portrait), Windows and Web — no Android/macOS/Linux folders. It imports a student list from Excel, randomly splits it into evenly sized groups with an animated "draw", saves results locally, and exports them back to Excel. All data stays on-device.

## Commands

```bash
flutter pub get
flutter run -d windows        # or: flutter run -d chrome / -d ios
flutter analyze               # lints: package:flutter_lints (platform folders and build/ excluded)
flutter test                  # all tests
flutter test test/core_test.dart                          # one file
flutter test test/core_test.dart --plain-name 'assignEvenly'   # one test by name
dart run build_runner build   # regenerate lib/data/database.g.dart after changing tables
flutter build windows
flutter build web
flutter build ios --simulator --debug   # quick iOS compile check, no signing needed
```

## Architecture

Layers under `lib/`:

- `models/models.dart` — plain immutable domain models (`ClassModel`, `GroupModel`, `Student`, `GroupDraft`). UI code works only with these, never with drift row classes.
- `data/database.dart` — drift schema: `Classes` → `Students` and `Groups` (cascade delete) → `Members` (join table, PK `groupId+studentId`, ordered by `position`). `orderIndex` columns preserve import/creation order. Foreign keys are enabled via `PRAGMA` in `beforeOpen`. `database.g.dart` is generated — don't hand-edit it.
- `data/class_repository.dart` — the only code that touches the DB; maps rows to models. Imports `database.dart` with `hide Student` because drift generates a `Student` row class that clashes with the domain model. `saveAssignment` replaces all memberships for a class in one transaction.
- `data/providers.dart` — Riverpod providers (`databaseProvider`, `repositoryProvider`, `classListProvider`, `classProvider(id)`). Read providers are `autoDispose` futures with no reactive DB streams, so screens must `ref.invalidate(...)` them after writes or after returning from a pushed route.
- `core/` — pure logic: `shuffle_service.dart` (`assignEvenly`: shuffle then round-robin, so sizes differ by ≤1; takes an optional `Random` for tests) and `excel_service.dart` (`parseStudents` reads column A of the first sheet and drops a header row if it matches a known header word, including Vietnamese ones; `buildExport` writes "Groups" and "Summary" sheets).
- `features/` — screens, routed by go_router in `main.dart`: `/` home list, `/new` class form, `/draw/:id` animated draw, `/class/:id` saved result + export. Home opens `/class/:id` if a class already has a result (`ClassModel.hasResult`), otherwise `/draw/:id`.

### Draw screen

`features/draw/draw_screen.dart` computes the final assignment up front, then animates toward it with timers through phases `loading` (~0.5s) → `scramble` (4 shuffles at 250ms) → `dealing` (batches at 33ms ticks, ~1.5s total) → `done`. Total is ~3s, and `test/draw_test.dart` relies on that timing (Save appears only after ~3.2s). Layout is manual: a `Stack` of `AnimatedPositioned` name cards keyed by student id, with positions computed from fixed constants (group boxes on top, unassigned pool below). Group boxes grow with the deepest filled slot rather than their final size, so on a phone the shuffling pool stays on screen until names are dealt. Below `_narrowWidth` (600) the pool cards stretch to fill 3 columns and the done-state actions (Re-roll / Save / View-Export) move from the app bar to a bottom bar. Skip jumps straight to `done`; Re-roll restarts with a new assignment. Nothing is persisted until the user presses Save.

## Platform notes

- **iOS:** iPhone is portrait-only via `UISupportedInterfaceOrientations` in `ios/Runner/Info.plist`; iPad keeps all orientations (needed for multitasking). Minimum iOS 15 (file_picker needs 14+). Bundle ID `com.luanvo.teacherTeamDice`. Import uses the system document picker; export uses file_saver's `saveAs`, which opens "Save to Files" and returns `null` on cancel. Scrollable bodies add `MediaQuery.paddingOf(context).bottom` so content clears the home indicator.
- **Web:** `AppDatabase` uses `drift_flutter`'s `driftDatabase` with `web/sqlite3.wasm` and `web/drift_worker.js`; both are committed and required for the web build. If you upgrade drift/sqlite3, these files may need to be replaced with matching versions.

## Testing

Tests build the DB with `AppDatabase(NativeDatabase.memory())` and override `repositoryProvider` in a `ProviderScope`. Widget tests that hit drift need `tester.runAsync` for real async DB work. `test/draw_test.dart` runs the draw at both desktop (1200×900) and phone (390×844) sizes. Keep the phone case passing when changing the draw layout. `samples/students_59.xlsx` is a sample import file for manual testing.
