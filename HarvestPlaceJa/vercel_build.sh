#!/usr/bin/env bash
set -euo pipefail

echo "=== HPJ Vercel Flutter Web Build ==="

FLUTTER_DIR="$HOME/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Installing Flutter stable..."
  git clone https://github.com/flutter/flutter.git     --depth 1     --branch stable     "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web

echo "Getting packages..."
flutter pub get

echo "Building HPJ web release..."
flutter build web --release

echo "=== HPJ web build complete ==="
