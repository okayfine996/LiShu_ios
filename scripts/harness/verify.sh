#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-full}"
PROJECT="LiShu.xcodeproj"
SCHEME="LiShu"
DESTINATION="${LISHU_XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max}"

usage() {
  cat <<'USAGE'
Usage: scripts/harness/verify.sh [quick|full|ui|release]

Environment:
  LISHU_XCODE_DESTINATION  Override xcodebuild destination.

Modes:
  quick    SwiftFormat lint, SwiftLint, and xcodebuild build.
  full     quick plus all LiShuTests.
  ui       all LiShuUITests.
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
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" build
}

run_unit_tests() {
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -parallel-testing-enabled NO test -only-testing:LiShuTests
}

run_ui_tests() {
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -parallel-testing-enabled NO test -only-testing:LiShuUITests
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
    run_ui_tests
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
