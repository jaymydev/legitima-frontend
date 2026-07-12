#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/legitima-frontend.xcodeproj"
SCHEME="legitima-frontend"
DERIVED_DATA_PATH="$ROOT_DIR/.build/DerivedData"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is not available. Install Xcode command line tools first."
  exit 1
fi

echo "==> Building $SCHEME"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build
