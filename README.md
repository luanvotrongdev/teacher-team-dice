# Team Dice 🎲

A fun little project I built for my wife, who is a university teacher.

It is growing into a small toolbox for teachers. The app opens on a main menu where you pick a tool. It runs on **iPhone / iPad** (portrait and landscape), **Windows** and **Web**.

## Tools

### Team Dice

Splitting a class into groups and handing out projects is a chore. Team Dice does it with a bit of fun: load the student list, press **Random**, and watch the names get shuffled and dealt into groups.

- Create a class: name, student list from an Excel file, number of groups, group names and project names
- **Random** button with a ~3 second animation: names load, scramble, then fly one by one into their groups
- Groups are split evenly (sizes differ by at most one)
- Save results to a local database to reopen and check later
- Export saved groups to Excel

### Word Lottery

Give the class a random prompt to work with. Each column of an Excel sheet is a list of words (for example: who, does what, to what, where). Press **Lottery** and the app picks one word from every column.

- Create a quiz: give it a name, then import an Excel file
- Empty rows and columns are removed, and a confirmation screen shows what was read before anything is saved
- **Lottery** button rolls the words for a moment, then shows one combination (never the same one twice in a row)
- The words are shown side by side in landscape, and stacked top to bottom in portrait
- Delete a quiz from its screen

## Word Lottery Excel format

A single `.xlsx` file with **one sheet**. Each column is a list of words. Columns can have different lengths, and blank cells are skipped. There is no header row: every cell counts as a word. See `samples/word_lottery_sample.xlsx`.

| A | B | C |
|---|---|---|
| I | want to buy | a new phone |
| You | design | a coffee brand |
| Our team | sell | |

## Student Excel format (Team Dice)

A single `.xlsx` file. Student names go in **column A** of the first sheet. A header row (for example `Name`) is optional and is skipped automatically.

| A |
|---|
| Name |
| Student 1 |
| Student 2 |

## Getting started

Requires [Flutter](https://flutter.dev) (stable).

```bash
flutter pub get
flutter run -d windows   # or: flutter run -d chrome
flutter run -d ios       # iPhone simulator or device (macOS + Xcode only)
```

Build a release:

```bash
flutter build windows
flutter build web
flutter build ipa        # needs an Apple signing team set in Xcode
```

For the App Store, use the release script. It runs the checks, then builds a signed `.ipa` whose build number is the current time (`yyyyMMddHHmm`, e.g. `202611061430`), so every upload gets a new number. The version name comes from `pubspec.yaml`.

```bash
scripts/build_ios_release.sh                 # analyze, test, build
scripts/build_ios_release.sh --skip-checks   # build only
scripts/build_ios_release.sh --name 1.1.0    # different version name
```

The `.ipa` lands in `build/ios/ipa/`. Upload it with Apple's Transporter app, or run with `--open` to upload from Xcode's Organizer.

## On iPhone

- Works in portrait and landscape. Turn the phone sideways to see a Word Lottery combination in one line.
- To import a file (students or words), put the `.xlsx` file somewhere the Files app can see (iCloud Drive, On My iPhone, AirDrop, or "Save to Files" from Mail), then tap **Import**.
- **Export Excel** opens the iOS "Save to Files" dialog.

Run the tests:

```bash
flutter test
```

## Tech

Flutter, Riverpod, go_router, drift (SQLite on iOS and Windows, in the browser on Web), `excel`, `file_picker`, `file_saver`.

Data is stored only on the device (or in the browser), nothing is sent anywhere.

## Notes

- Each tool lives in `lib/tools/<name>/` and is listed in `lib/app/tools.dart`. See "Adding a tool" in `CLAUDE.md`.
- All tools share one local database (`lib/shared/database/app_database.dart`). If you change any tables, regenerate code with `dart run build_runner build`.
- The web build needs `web/sqlite3.wasm` and `web/drift_worker.js`, which are included in the repo.

Made with ❤️ for my wife.
