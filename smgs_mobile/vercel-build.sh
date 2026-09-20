#!/bin/bash
echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
export PATH="$PATH:$(pwd)/_flutter/bin"

echo "Flutter version:"
flutter --version

echo "Building Flutter Web..."
flutter config --enable-web
flutter pub get
flutter build web --release
