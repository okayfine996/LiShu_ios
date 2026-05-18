#!/bin/sh
set -e

# Install tools required for Xcode Cloud build and archive.
# xcbeautify is used for readable xcodebuild output.
brew install swiftformat swiftlint xcbeautify

# Periphery dead-code scanner is only needed during archive (Release workflow).
if [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
    brew install peripheryapp/periphery/periphery
fi
