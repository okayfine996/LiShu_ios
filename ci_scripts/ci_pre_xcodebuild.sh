#!/bin/sh
set -e

# Lint and format checks run in GitHub Actions for fast PR feedback.
# This hook is reserved for future pre-build steps (e.g., code generation,
# environment validation) that must run inside the Xcode Cloud environment.
