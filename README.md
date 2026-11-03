# Team Dice 🎲

A fun little project I built for my wife, who is a university teacher.

Splitting a class into groups and handing out projects is a chore. Team Dice does it with a bit of fun: load the student list, press **Random**, and watch the names get shuffled and dealt into groups.

## Features

- Create a class: name, student list from an Excel file, number of groups, group names and project names
- **Random** button with a ~3 second animation: names load, scramble, then fly one by one into their groups
- Groups are split evenly (sizes differ by at most one)
- Save results to a local database to reopen and check later
- Export saved groups to Excel
- Runs on **Windows** and **Web**

## Student Excel format

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
```

Build a release:

```bash
flutter build windows
flutter build web
```

Run the tests:

```bash
flutter test
```

## Tech

Flutter, Riverpod, go_router, drift (SQLite locally on Windows, in the browser on Web), `excel`, `file_picker`, `file_saver`.

Data is stored only on the device (or in the browser), nothing is sent anywhere.

## Notes

- If you change the database tables, regenerate code with `dart run build_runner build`.
- The web build needs `web/sqlite3.wasm` and `web/drift_worker.js`, which are included in the repo.

Made with ❤️ for my wife.
