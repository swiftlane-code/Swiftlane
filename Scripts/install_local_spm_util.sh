#!/bin/bash

set -euo pipefail

WRONG_PARAMS_NUMBER_MSG="💥 Error: wrong number of parameters!"

function check_var_empty() {
    local var_name=$1
    if [[ "$(printenv $var_name)" == "" ]]; then
        echo "Env var \"$var_name\" is empty!"
        exit 1
    fi
}

check_var_empty SM_UTILS_PATH
check_var_empty SM_UTILS_BIN_PATH

mkdir -p $SM_UTILS_PATH
mkdir -p $SM_UTILS_BIN_PATH


read_current_git_state() {
    if [ "$#" -ne 1 ]; then
        echo $WRONG_PARAMS_NUMBER_MSG
        exit 1
    fi

    local cloned_dir_name=$1

    if [ ! -d "$cloned_dir_name/.git" ]; then
        CURRENT_GIT_COMMIT="not-a-git-repo"
    else
        CURRENT_GIT_COMMIT=$(git -C "$cloned_dir_name" rev-parse HEAD) # current commit SHA
    fi
}


clone_if_needed() {
    if [ "$#" -ne 3 ]; then
        echo $WRONG_PARAMS_NUMBER_MSG
        exit 1
    fi

    local repo_url=$1
    local cloned_dir_name=$2
    local target_tag=$3

    local correct_git_dir="$cloned_dir_name/.git"
    local actual_util_git_dir="$cloned_dir_name/$(git -C "$cloned_dir_name" rev-parse --git-dir || echo '<damaged>')"

    # Check if path to ".git" dir recognized by git is the same as expected path to the util's ".git" dir.
    if [ "$correct_git_dir" -ef "$actual_util_git_dir" ]; then
        echo "Existing git dir at \"$correct_git_dir\" is correct."
        return
    fi

    echo "✨ \"$correct_git_dir\" is damaged or doesn't exist."
    echo "✨ Cloning $repo_url into $(pwd)/$cloned_dir_name..."

    rm -rf "$cloned_dir_name"
    mkdir -p "$cloned_dir_name"
    git clone \
        --depth 1 \
        --branch "$target_tag" \
        --no-tags \
        -c "advice.detachedHead=false" \
        "$repo_url" "$cloned_dir_name"
}

safety_checkout_to_tag() {
    if [ "$#" -ne 3 ]; then
        echo $WRONG_PARAMS_NUMBER_MSG
        exit 3
    fi

    local cloned_dir_name=$1
    local target_tag=$2
    local repo_url=$3

    cd $cloned_dir_name > /dev/null

    # check that .git dir is not damaged
    if [ ! "$(git rev-parse --git-dir)" -ef ".git" ]; then
        echo "💥 Looks like .git dir is damaged at \"$(pwd)/.git\""
        exit 2
    fi

    # ensure url is correct
    git remote set-url origin "$repo_url"
    git reset --hard > /dev/null
    git clean -fdx --exclude "/.build"

    # check current tag
    if [ "$(git describe --tags)" == "$target_tag" ]; then
        echo "✅ Already on tag \"$target_tag\""
        cd - > /dev/null
        return
    fi

    echo "✨ Fetching tag \"$target_tag\"..."
    git fetch origin tag \
        --no-tags \
        --verbose \
        --depth 1 \
        "$target_tag"

    echo "✨ Checking out tag \"$target_tag\"..."
    git -c "advice.detachedHead=false" \
        checkout \
        "tags/$target_tag"

    cd - > /dev/null

    echo "✅ Cloned and checked out tag \"$target_tag\"."
}

build() {
    if [ "$#" -lt 2 ]; then
        echo $WRONG_PARAMS_NUMBER_MSG
        exit 4
    fi

    local util_name=$1
    local project_path=$2

    cd $project_path

    start=$(date +%s)
    echo "🛠  Compiling $util_name..."

    swift build -c release -Xswiftc -suppress-warnings
    BUILT_BINARY_DIR=`swift build -c release --show-bin-path`

    echo "✅ Compiled $util_name in $(($(date +%s) - ${start})) seconds"

    cd -
}

clean_build_cache() {
    if [ "$#" -lt 1 ]; then
        echo $WRONG_PARAMS_NUMBER_MSG
        exit 4
    fi

    local project_path=$1

    cd $project_path

    echo "Cleaning build cache at $project_path..."
    swift package reset

    cd -
}

move_executable() {
    local built_binary_dir=$1
    local execulable_name=$2
    local moved_binary_path=$3

    echo "Moving built binary to ./$moved_binary_path"
    mv -f $built_binary_dir/$execulable_name $moved_binary_path

    local bundle_destination_dir=$(dirname $moved_binary_path)
    for BUNDLE_PATH in $built_binary_dir/*.bundle; do
        local bundle_name=$(basename $BUNDLE_PATH)
        if [ "$bundle_name" == "*.bundle" ]; then
            return
        fi
        rm -rf $bundle_destination_dir/$bundle_name
        mv -f $BUNDLE_PATH $bundle_destination_dir/$bundle_name
    done
}

main() {
    if [[ "$#" -ne 3 ]]; then
        echo $WRONG_PARAMS_NUMBER_MSG
        exit 4
    fi

    echo "🤓 Currect location: $(pwd)"

    local repo_url=$1
    local target_tag=$2
    local execulable_name=$3

    local util_name=`echo $repo_url | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1`
    local cloned_dir_name="$SM_UTILS_PATH/$util_name/"

    mkdir -p "$SM_UTILS_PATH"

    start=$(date +%s)
    echo "⏬ Cloning $util_name $repo_url"

    read_current_git_state $cloned_dir_name
    PREVIOUS_STATE_GIT_COMMIT="$CURRENT_GIT_COMMIT"

    clone_if_needed $repo_url $cloned_dir_name $target_tag
    safety_checkout_to_tag $cloned_dir_name $target_tag $repo_url

    read_current_git_state $cloned_dir_name

    echo "✅ Cloned $util_name in $(($(date +%s) - ${start})) seconds"
    echo

    local moved_binary_path=$SM_UTILS_BIN_PATH/$execulable_name

    if [[ -f "$moved_binary_path" ]]; then
        # Link is valid and target executable file exist"

        if [[ "$CURRENT_GIT_COMMIT" == "$PREVIOUS_STATE_GIT_COMMIT" ]]; then
            echo "😇 Skipping utility \"$util_name\" rebuilding attempt because git state did not change after checkout."
            echo "💡 If not agree, run '\$ rm -rf \"$cloned_dir_name\"' command and rerun this script."
            echo
            exit 0
        fi

        echo "☢️  Git state changed from $PREVIOUS_STATE_GIT_COMMIT to $CURRENT_GIT_COMMIT. Compilation required."

        # making sure next run will rebuild in case this build fails.
        echo "Removing binary at $moved_binary_path"
        rm "$moved_binary_path"
    else
        echo "☢️  Binary doesn't exist. Compilation required."
    fi

    build $util_name $cloned_dir_name
    move_executable $BUILT_BINARY_DIR $execulable_name $moved_binary_path
    clean_build_cache $cloned_dir_name
}

main $@
