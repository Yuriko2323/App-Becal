#!/usr/bin/env bash

set -e

git clone --depth 1 --branch stable \
  https://github.com/flutter/flutter.git /tmp/flutter

export PATH="/tmp/flutter/bin:$PATH"

flutter config --enable-web

flutter pub get

flutter build web --release