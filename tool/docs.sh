#!/bin/sh

pub get

# Have to remove ./dartdoc-viewer before regenerating to avoid an exception
# See: https://github.com/dart-lang/homebrew-dart/issues/16#issuecomment-84341326
if [ -d "./dartdoc-viewer" ]; then
    rm -rf ./dartdoc-viewer
fi

# Generate docs from Dart source code
# --introduction=README.md
#       Creates an introduction page using this repo's README
# --compile
#       runs output through dart2js
dartdocgen --introduction=README.md --compile --serve .