#!/bin/bash

set -euo pipefail

source ./Scripts/bootstrap_dirs.sh

echo "Resolving package..."
swift package resolve

echo "🦄 Installing local utilities..."
# Use newer Sourcery version that compiles with modern Swift
./Scripts/install_local_spm_util.sh "https://github.com/krzysztofzablocki/Sourcery.git" "2.3.0" "sourcery"
echo "✅ Local utilities installed"

echo "🦄 Cleaning generated Swift files"
for FOLDER in "Sources Tests"; do
	find $FOLDER -name '*.generated.swift' -delete
done
echo "✅ Generated Swift files successfully deleted"

echo "🦄 Generating Mocks..."
# Use SwiftyMocky from the resolved package
.build/checkouts/SwiftyMocky/bin/swiftymocky generate
echo "✅ Tests Mocks successfully generated"

# echo "🦄 Formatting Mocks..."
# ./format_code Sources/SwiftlaneCoreMocks
# echo "✅ All done!"
