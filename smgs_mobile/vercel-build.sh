#!/bin/bash
set -euo pipefail

echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:$(pwd)/_flutter/bin"

echo "Flutter version:"
flutter --version

echo "Building Flutter Web..."
flutter config --enable-web
flutter pub get
flutter build web --release

# model_viewer_plus requests bundled models from /assets/models on web, while
# Flutter stores app assets under /assets/assets in a release build. Publish a
# stable static URL for Vercel so the GLB is not caught by the SPA rewrite.
mkdir -p build/web/assets/models
cp assets/models/trong_dong_dong_son.glb build/web/assets/models/trong_dong_dong_son.glb
test -s build/web/assets/models/trong_dong_dong_son.glb
