#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-full}"
PROJECT="LiShu.xcodeproj"
SCHEME="LiShu"

resolve_destination() {
  if [[ -n "${LISHU_XCODE_DESTINATION:-}" ]]; then
    echo "$LISHU_XCODE_DESTINATION"
    return
  fi

  local preferred_name id
  for preferred_name in "iPhone 17 Pro" "iPhone 17" "iPhone 17 Pro Max" "iPhone 16 Pro"; do
    id="$(xcrun simctl list devices available 2>/dev/null | awk -v name="$preferred_name" 'index($0, "    " name " (") == 1 { if (match($0, /\([A-F0-9-]+\)/)) { print substr($0, RSTART + 1, RLENGTH - 2); exit } }')"
    if [[ -n "$id" ]]; then
      echo "platform=iOS Simulator,id=$id"
      return
    fi
  done

  echo "generic/platform=iOS Simulator"
}

DESTINATION="$(resolve_destination)"

usage() {
  cat <<'USAGE'
Usage: scripts/harness/verify.sh [quick|full|ui|release]

Environment:
  LISHU_XCODE_DESTINATION  Override xcodebuild destination.

Modes:
  quick    SwiftFormat lint, SwiftLint, and xcodebuild build.
  full     quick plus all LiShuTests.
  ui       build-for-testing, then all LiShuUITests.
  release  full plus ui and fastlane environment notes.
USAGE
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    return 1
  fi
}

run_swiftformat() {
  require_tool swiftformat
  swiftformat LiShu LiShuTests LiShuUITests --lint --config .swiftformat
}

run_swiftlint() {
  require_tool swiftlint
  swiftlint lint --strict
}

run_build() {
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" build-for-testing
}

run_unit_tests() {
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -parallel-testing-enabled NO test-without-building -skip-testing:LiShuUITests
}

run_ui_tests() {
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -parallel-testing-enabled NO test-without-building -only-testing:LiShuUITests
}

run_ui() {
  run_build
  run_ui_tests
}

run_quick() {
  run_swiftformat
  run_swiftlint
  run_build
}

run_full() {
  run_quick
  run_unit_tests
}

case "$MODE" in
  quick)
    run_quick
    ;;
  full)
    run_full
    ;;
  ui)
    run_ui
    ;;
  release)
    run_full
    run_ui_tests
    if command -v fastlane >/dev/null 2>&1; then
      echo "fastlane is available. Run screenshot or release lanes only when needed:"
      echo "  fastlane ios screenshots"
      echo "  fastlane ios frameit"
      echo "  fastlane ios store_screenshots"
      echo "  fastlane ios ipa"
    else
      echo "fastlane is not installed; release screenshot/archive checks were not run."
      exit 1
    fi
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
