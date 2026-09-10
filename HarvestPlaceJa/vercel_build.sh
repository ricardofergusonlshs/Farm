#!/usr/bin/env bash
set -euo pipefail

echo "=== HPJ Vercel Flutter Web Build ==="

FLUTTER_VERSION="3.32.8"
FLUTTER_DIR="$HOME/flutter"

if [ -d "$FLUTTER_DIR" ]; then
  rm -rf "$FLUTTER_DIR"
fi

echo "Installing Flutter $FLUTTER_VERSION..."
git clone \
  --depth 1 \
  --branch "$FLUTTER_VERSION" \
  https://github.com/flutter/flutter.git \
  "$FLUTTER_DIR"

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web

echo "Getting packages..."
flutter pub get

echo "Building HPJ web release..."
flutter build web --release

echo "=== HPJ web build complete ==="
