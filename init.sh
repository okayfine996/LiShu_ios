#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "LiShu harness startup"
echo "Root: $ROOT_DIR"
echo

echo "Git status:"
git status --short
echo

echo "Harness files:"
required_files=(
  "AGENTS.md"
  "CLAUDE.md"
  "docs/harness/PRODUCT.md"
  "docs/harness/ARCHITECTURE.md"
  "docs/harness/ENGINEERING_RULES.md"
  "docs/harness/VERIFICATION.md"
  "docs/harness/WORKFLOW.md"
  ".harness/feature_list.json"
  ".harness/progress.md"
  ".harness/session-handoff.md"
  ".harness/decisions.md"
  "scripts/harness/verify.sh"
)

missing=0
for file in "${required_files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "  ok      $file"
  else
    echo "  missing $file"
    missing=1
  fi
done
echo

echo "Active feature:"
if command -v python3 >/dev/null 2>&1; then
  python3 -c 'import json; print(json.load(open(".harness/feature_list.json"))["active_feature_id"])' 2>/dev/null || echo "  unable to parse .harness/feature_list.json"
else
  echo "  python3 not found; inspect .harness/feature_list.json manually"
fi
echo

echo "Xcode project:"
xcodebuild -list -project LiShu.xcodeproj
echo

echo "Tool availability:"
for tool in swiftformat swiftlint fastlane; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "  ok      $tool"
  else
    echo "  missing $tool"
  fi
done
echo

echo "Recommended next reads:"
echo "  .harness/progress.md"
echo "  .harness/session-handoff.md"
echo "  docs/harness/WORKFLOW.md"
echo

if [[ "$missing" -ne 0 ]]; then
  echo "Harness startup completed with missing files."
  exit 1
fi

echo "Harness startup completed."
