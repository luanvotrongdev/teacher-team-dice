# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A multi-tool Flutter app for teachers. It targets iOS first (iPhone in portrait), plus Windows and Web; there are no Android/macOS/Linux folders. The app opens on a main menu, and the user picks a tool from it. More tools will be added. Today there are two:
- **Team Dice**: import a student list from Excel, split it into random even groups with an animated draw, save locally, and export to Excel.
- **Word Lottery**: import an Excel sheet where each column is a list of words, save it as a named quiz, and press Lottery to draw one random word from every column.

All data stays on-device.

The in-app name is a placeholder (`appName` in `lib/app/app.dart`, currently "Teacher Tools"). Platform display names (iOS `Info.plist`, `web/index.html` + `manifest.json`, Windows `Runner.rc`) still say "Team Dice". The package name stays `teacher_team_dice`.

## Commands

```bash
flutter pub get
flutter run -d windows        # or: flutter run -d chrome / -d ios
flutter analyze               # lints: package:flutter_lints (platform folders and build/ excluded)
flutter test                  # all tests
flutter test test/tools/word_lottery/core_test.dart                       # one file
flutter test test/tools/team_dice/core_test.dart --plain-name 'assignEvenly'   # one test by name
dart run build_runner build   # regenerate lib/shared/database/app_database.g.dart after changing any tables
flutter build windows
flutter build web
flutter build ios --simulator --debug   # quick iOS compile check, no signing needed
```

## Architecture

```
lib/
  main.dart            ProviderScope + TeacherToolsApp
  app/                 the shell: knows about every tool
    tool.dart          ToolDefinition (id, name, description, icon, home, routes)
    tools.dart         appTools: the registry, in menu order
    router.dart        `/` = main menu; each tool mounted at `/<id>` as a child route
    main_menu_screen.dart, app.dart
  shared/              code used by more than one tool
    database/          AppDatabase (the one drift DB) + databaseProvider
  tools/<tool>/        everything a tool owns
```

- **Tools are self-contained.** A tool folder holds its screens, logic, models, repository, providers and drift tables. It exposes one `ToolDefinition`, plus a `routes.dart` of absolute path helpers (e.g. `TeamDiceRoutes.draw(id)`) so its screens don't hardcode URLs. Tools must not import each other. Anything two tools need goes in `lib/shared/`.
- **Routing.** Tool routes are nested under `/`, so `context.go('/team-dice/...')` always builds a stack with the main menu at the bottom, and the tool's start screen gets an automatic back button to the menu. A tool's sub-routes are relative to its id.
- **One database.** `AppDatabase` (`lib/shared/database/app_database.dart`) lists every tool's tables. Tools get it through `databaseProvider` and wrap it in their own repository. Sharing data between tools is not designed yet. The single DB keeps that open: a later tool can read another tool's tables, or shared tables (e.g. a class roster) can be promoted into `lib/shared/`. The DB name stays `teacher_team_dice` so data saved before the multi-tool restructure still opens.
- **Drift table class names are SQL table names.** Renaming `Classes`, `Students`, `Groups` or `Members` (or reusing those names in another tool) breaks existing data. Prefix a new tool's tables if names could clash. Drift generates row classes (e.g. `Student`) into the database library, which can clash with domain models. Team Dice imports the DB with `hide Student` for this reason.
- **State.** Riverpod. Read providers are `autoDispose` futures with no reactive DB streams, so screens must `ref.invalidate(...)` them after writes.
  - The screen that writes should invalidate the list provider itself.
  - Don't rely on `await context.push(...)` returning: go_router never completes that future if the pushed screen is later swapped by `pushReplacement` or left via `go`. Both tools do exactly that (new → draw/play, delete → `go(home)`).

### Adding a tool

1. Create `lib/tools/<name>/` with a `<name>_tool.dart` exporting a `ToolDefinition` (URL-safe unique `id`), and a `routes.dart` for its paths.
2. Add it to `appTools` in `lib/app/tools.dart`. It then appears in the main menu and router.
3. If it stores data: define tables in `lib/tools/<name>/data/tables.dart`, add them to `@DriftDatabase(tables: [...])` in `app_database.dart`, bump `schemaVersion`, add an `onUpgrade` step that creates the new tables, then run `dart run build_runner build`. Word Lottery is the worked example (schema 2), with a test that upgrades a schema-1 database.
4. Put tests under `test/tools/<name>/`.

### Team Dice (`lib/tools/team_dice/`)

- `models/` holds plain immutable domain models (`ClassModel`, `GroupModel`, `Student`, `GroupDraft`). UI code uses these, never drift rows.
- `data/` holds the tables (`Classes` → `Students`/`Groups` with cascade delete → `Members` join table ordered by `position`; `orderIndex` keeps import order), `ClassRepository` (the only DB access; `saveAssignment` replaces memberships in one transaction) and providers.
- `core/` is pure logic:
  - `assignEvenly` shuffles then deals round-robin, so group sizes differ by ≤1.
  - `parseStudents` reads column A of the first sheet and drops a known header word (including Vietnamese ones).
  - `buildExport` writes "Groups" and "Summary" sheets.
- `features/` holds the screens: home (class list) → new class form → draw → saved result/export. Home opens the result if the class has one, otherwise the draw.

The draw screen (`features/draw/draw_screen.dart`) computes the final assignment up front, then animates toward it on timers:
- **Phases:** `loading` (~0.5s) → `scramble` (4 shuffles at 250ms) → `dealing` (33ms ticks, ~1.5s) → `done`. That's ~3s in total, and `test/tools/team_dice/draw_test.dart` depends on that timing.
- **Layout:** manual. A `Stack` of `AnimatedPositioned` name cards keyed by student id, with group boxes on top and the pool below. Group boxes grow with the deepest filled slot, so on a phone the shuffling pool stays on screen.
- **Narrow screens:** below `_narrowWidth` (600), pool cards fill 3 columns and the done-state actions move to a bottom bar.
- **Saving:** nothing is persisted until Save.

### Word Lottery (`lib/tools/word_lottery/`)

- **Tables:** `LotteryQuizzes` → `LotteryWords` (cascade delete). Each word row has `columnIndex` and `position`. Row classes are renamed with `@DataClassName` (`LotteryQuizRow`, `LotteryWordRow`), so the `Quiz` domain model doesn't clash.
- **Import** (`core/excel_import.dart`, `parseQuizSheet`):
  - Every cell is trimmed. Fully empty rows and columns are dropped.
  - Blank sheets are ignored. More than one sheet with content is an error.
  - It returns a `QuizDraft` with `rows`, the trimmed grid shown on the confirmation screen, and `columns`, each column's words with gaps skipped. Only `columns` is saved.
  - There is no header-row detection: every cell is a word.
- **Draw:** `core/lottery.dart` `drawCombination` picks one word per column. When given the previous result, it won't repeat it if another combination exists.
- **Screens:**
  - `features/saved/home_screen.dart`: the quiz list.
  - `features/quiz_form/quiz_form_screen.dart`: name → import → confirmation, all one screen. A `PopScope` sends Back from the confirmation step to the form, and nothing is saved until Confirm.
  - `features/play/play_screen.dart`: the Lottery button rolls the words for `LotteryBoard.rollDuration` (800ms), then settles. Delete is in the app bar.
- **File picking** goes through `quizFilePickerProvider`, so tests can supply bytes without the platform picker.

## Platform notes

- **iOS:**
  - iPhone is portrait-only via `UISupportedInterfaceOrientations` in `ios/Runner/Info.plist`. iPad keeps all orientations, because multitasking needs them.
  - Minimum iOS 15 (file_picker needs 14+). Bundle ID `com.luanvo.teacherTeamDice`.
  - Import uses the system document picker. Export uses file_saver's `saveAs` ("Save to Files"), which returns `null` on cancel.
  - Scrollable bodies add `MediaQuery.paddingOf(context).bottom` so content clears the home indicator.
- **Web:** the database needs `web/sqlite3.wasm` and `web/drift_worker.js` (both committed). They may need replacing when drift/sqlite3 is upgraded.

## Testing

- Tests use `AppDatabase(NativeDatabase.memory())` and override `databaseProvider` (whole app) or a tool's repository provider in a `ProviderScope`. Widget tests that hit drift need `tester.runAsync` for real async DB work.
- `test/app/main_menu_test.dart` covers the menu and tool navigation. `TeacherToolsApp(tools: [...])` accepts fake tools.
- Full-app flows: `test/tools/word_lottery/flow_test.dart` (create → confirm → draw → back → delete) and `test/tools/team_dice/home_test.dart` (delete refreshes the list). Both build .xlsx bytes in memory with the `excel` package.
- The draw test runs at desktop (1200×900) and phone (390×844) sizes.
- Sample import files: `samples/students_59.xlsx` (Team Dice) and `samples/word_lottery_sample.xlsx` (Word Lottery, 4 columns).
