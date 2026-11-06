#!/usr/bin/env bash
# Builds a signed App Store .ipa (Xcode archive + export) for upload.
#
# The build number is the current local time as yyyyMMddHHmm (24-hour clock),
# e.g. 202611061430, so every build gets a new, increasing number.
# The version name comes from pubspec.yaml (the part before "+").
#
# Usage:
#   scripts/build_ios_release.sh                 # analyze, test, then build
#   scripts/build_ios_release.sh --skip-checks   # build only
#   scripts/build_ios_release.sh --name 1.1.0    # override the version name
#   scripts/build_ios_release.sh --open          # also open the archive in Xcode Organizer
#
# Output:
#   build/ios/ipa/*.ipa                 upload with Transporter
#   build/ios/archive/Runner.xcarchive  or upload from Xcode Organizer

set -euo pipefail

cd "$(dirname "$0")/.."

skip_checks=false
open_archive=false
build_name=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-checks) skip_checks=true ;;
    --open) open_archive=true ;;
    --name)
      [[ $# -ge 2 ]] || { echo "error: --name needs a value, e.g. --name 1.1.0" >&2; exit 2; }
      build_name="$2"
      shift
      ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: iOS builds need macOS with Xcode." >&2
  exit 1
fi
command -v flutter >/dev/null || { echo "error: flutter is not on PATH." >&2; exit 1; }

# CocoaPods fails with non-UTF-8 locales.
export LANG="${LANG:-en_US.UTF-8}"
[[ "$LANG" == *UTF-8* ]] || export LANG=en_US.UTF-8

if [[ -z "$build_name" ]]; then
  build_name="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' pubspec.yaml)"
  [[ -n "$build_name" ]] || { echo "error: could not read version from pubspec.yaml" >&2; exit 1; }
fi
build_number="$(date +%Y%m%d%H%M)"

if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  echo "warning: uncommitted changes will be included in this build."
fi

echo "==> Version $build_name ($build_number)"

if [[ "$skip_checks" == false ]]; then
  echo "==> flutter analyze"
  flutter analyze
  echo "==> flutter test"
  flutter test
fi

archive="build/ios/archive/Runner.xcarchive"
# Clear the last export so a failed signing step can't leave an old .ipa looking new.
rm -rf build/ios/ipa

echo "==> flutter build ipa"
flutter build ipa --release --build-name "$build_name" --build-number "$build_number"

ipa="$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -n 1 || true)"

echo
echo "Built version $build_name, build $build_number"
echo "  Archive: $archive"
if [[ -n "$ipa" ]]; then
  echo "  IPA:     $ipa"
  echo "Upload the IPA with the Transporter app, or open the archive in Xcode and choose Distribute App."
fi

if [[ "$open_archive" == true ]]; then
  open "$archive"
fi

# flutter exits 0 even when signing the export fails, so check for the file.
if [[ -z "$ipa" ]]; then
  echo "error: the archive was built, but no .ipa was exported. Check the signing messages above." >&2
  echo "       App Store signing needs a paid Apple Developer Program team with an iOS Distribution certificate." >&2
  exit 1
fi
