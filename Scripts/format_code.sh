#!/bin/bash

set -euo pipefail

source ./Scripts/bootstrap_dirs.sh

SM_SWIFT_FORMAT_NAME="swiftformat"

./Scripts/install_local_spm_util.sh "https://github.com/nicklockwood/SwiftFormat.git" "0.49.14" "$SM_SWIFT_FORMAT_NAME"

SWIFT_VERSION=$(swift -version 2> /dev/null | head -n1 | cut -w -f 4)

echo "🦄 Starting code formatting ..."
args="$@"
if [ -z "$args" ]; then
	args="."
fi
$SM_UTILS_BIN_PATH/$SM_SWIFT_FORMAT_NAME $args --swiftversion "$SWIFT_VERSION"
echo "✅ Code formatting finished"
