#!/bin/sh
set -e

# Run Periphery dead-code scan after a successful archive (Release workflow).
# Non-blocking: warnings are printed but the build is not failed.
if [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
    echo "=== Periphery dead-code scan ==="
    periphery scan --quiet || echo "WARNING: Periphery found dead code"
fi
