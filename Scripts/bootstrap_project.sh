#!/bin/bash

set -euo pipefail

source ./Scripts/bootstrap_dirs.sh

echo "Resolving package..."
swift package resolve

echo "Getting resolved SwiftyMocky version..."
SWIFTYMOCKY_VERSION=$(swift package show-dependencies | grep -m 1 -Eo 'SwiftyMocky\.git@(.+)>' | grep -oE '\d+.\d+.\d+')

./Scripts/install_local_spm_util.sh "https://github.com/krzysztofzablocki/Sourcery.git" "1.8.0" "sourcery"
./Scripts/install_local_spm_util.sh "https://github.com/nstmrt/SwiftyMocky.git" "$SWIFTYMOCKY_VERSION" "swiftymocky"

echo "🦄 Cleaning generated Swift files"
for FOLDER in "Sources Tests"; do
	find $FOLDER -name '*.generated.swift' -delete
done
echo "✅ Generated Swift files successfully deleted"

echo "🦄 Generating Mocks..."
PATH="$(pwd)/$SM_UTILS_BIN_PATH/:$PATH" \
	"$SM_UTILS_BIN_PATH/swiftymocky" generate
echo "✅ Tests Mocks successfully generated"

# echo "🦄 Formatting Mocks..."
# ./format_code Sources/SwiftlaneCoreMocks
# echo "✅ All done!"
