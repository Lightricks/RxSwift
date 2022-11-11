#!/usr/bin/env bash
# Copyright (c) 2022 Lightricks. All rights reserved.
# Created by Eshed Shaham.

# Script for running swiftlint from within Xcode Run Script phase.

set -e

# Taken from https://stackoverflow.com/a/246128
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

if [[ "$SCRIPT_OUTPUT_FILE_0" != "$DERIVED_FILE_DIR/swiftlint.marker" ]]; then
  echo "error: Swiftlint Run Script phase must have \$(DERIVED_FILE_DIR)/swiftlint.marker" \
       "as its output"
  exit 1
fi

if [[ $SCRIPT_INPUT_FILE_COUNT -ne 0 ]]; then
  echo "error: Swiftlint Run Script phase must have no input files"
  exit 1
fi

if [[ $SCRIPT_OUTPUT_FILE_COUNT -ne 1 ]]; then
  echo "error: Swiftlint Run Script phase must have exactly one output file"
  exit 1
fi

pushd "$SRCROOT/$TARGET_NAME"

SWIFTLINT_YAML=.swiftlint.yml
# Find .swiftlint.yml recursively in the nearest parent directory.
SWIFTLINT_YAML_DIR=$(pwd)
while [ ! -e "$SWIFTLINT_YAML_DIR/$SWIFTLINT_YAML" ]; do
  SWIFTLINT_YAML_DIR=$( cd -- "$( dirname -- "$SWIFTLINT_YAML_DIR" )" &> /dev/null && pwd )

  if [ "$SWIFTLINT_YAML_DIR" = "" ]; then
    echo "error: No .swiftlint.yml file found in parent directories"
    exit 1
  fi
done
echo "note: Using configuration: $SWIFTLINT_YAML_DIR/$SWIFTLINT_YAML"

"$SCRIPT_DIR/swiftlint" --config "$SWIFTLINT_YAML_DIR/$SWIFTLINT_YAML"

popd

touch "$SCRIPT_OUTPUT_FILE_0"

DEPENDENCIES_FILE="$SCRIPT_OUTPUT_FILE_0.d"

echo "$SCRIPT_OUTPUT_FILE_0: \\" > "$DEPENDENCIES_FILE"
echo "$PROJECT_FILE_PATH/project.pbxproj \\" >> "$DEPENDENCIES_FILE"
echo "$SCRIPT_PATH \\" >> "$DEPENDENCIES_FILE"
find "$SRCROOT/$TARGET_NAME" -name "*.swift" | \
    sed "s/\ /\\\ /g" | tr '\n' ' ' >> "$DEPENDENCIES_FILE"
