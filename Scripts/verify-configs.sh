set -euo pipefail


export SM_SCRIPTS_DIR=$1

CONFIGS_DIR="$SM_SCRIPTS_DIR/c3po/configs"
PROJECT_DIR=$(pwd)



echo "$ swift build"
swift build # -c release

c3po=$(swift build --show-bin-path)/SwiftlaneCLI

echo

export GITLAB_API_ENDPOINT=fake_url
export PROJECT_ACCESS_TOKEN=fake_token
export JIRA_API_TOKEN=fake_token
export JIRA_API_ENDPOINT=fake_endpoint
export R2D2_HOOKS_ENDPOINT=fake_endpoint
export R2D2_AUTH_USERNAME=fake_username
export R2D2_AUTH_PASSWORD=fake_password
export GIT_AUTHOR_EMAIL=fake_email
export GITLAB_GROUP_DEV_TEAM_ID_TO_FETCH_MEMBERS=0
export ADP_ARTIFACTS_REPO=fake_url

SHARED_CONFIG_OPT="--shared-config $CONFIGS_DIR/shared.yml"
ONLY_VERIFY_OPT="--only-verify-configs"

# ==================================================== #

guardian_initial_note() {
	$c3po guardian-initial-note \
		--project-dir $PROJECT_DIR \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

guardian_before_build() {
	$c3po guardian-before-build \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/guardian-before-build.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

guardian_after_build() {
	$c3po guardian-after-build \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/guardian-after-build.yml" \
		--unit-tests-exit-code 0 \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

guardian_check_author() {
	$c3po guardian-check-author \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/guardian-check-author.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

qa_tests() {
	$c3po run-tests \
		--project-dir $PROJECT_DIR \
		--scheme SMQAUITestsPlans \
		--test-plan BaseTestPlan \
		--config "$CONFIGS_DIR/qa-tests.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

all_tests() {
	$c3po run-tests \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/all-tests.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

patch_test_plan_env() {
	$c3po patch-test-plan-env \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/patch-test-plan-env.yml" \
		--test-plan-name BaseTestPlan \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

change_jira_issue_labels() {
	$c3po change-jira-issue-labels \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/change-jira-issue-labels.yml" \
		--needed-labels "label1" \
		--needed-labels "label2" \
		--append-labels \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

check_commits() {
	$c3po check-commits \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/check-commits.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

setup_reviewers() {
	$c3po setup-reviewers \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/setup-reviewers.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

setup_assignee() {
	$c3po setup-assignee \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/setup-assignee.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

check_stop_list() {
	$c3po check-stop-list \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/check-stop-list.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

setup_labels() {
	$c3po setup-labels \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/setup-labels.yml" \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--verbose
}

setup_certs() {
	$c3po certs install \
		$ONLY_VERIFY_OPT \
		--config "$CONFIGS_DIR/setup-certs.yml" \
		--cloned-repo-dir $(pwd) \
		--keychain-password "fake password" \
		--repo-password "fake password" \
		--verbose
}

update_certs() {
	$c3po certs update \
		$ONLY_VERIFY_OPT \
		$SHARED_CONFIG_OPT \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/setup-certs.yml" \
		--cloned-repo-dir $(pwd) \
		--repo-password "fake password" \
		--auth-key-path "/Users/vmzhivetev/tmp/AuthKey_ABCDEFG.p8" \
		--auth-key-issuer-id "xxxxxxxxxxxx" \
		--bundle-id "ru.vmz.test-firebase-ipa-upload" \
		--bundle-id "ru.vmz.SimpleVpn" \
		--verbose
}

change_certs_password() {
	$c3po certs changepass \
		$ONLY_VERIFY_OPT \
		--config "$CONFIGS_DIR/setup-certs.yml" \
		--cloned-repo-dir $(pwd) \
		--verbose
}

upload_to_appstore() {
	$c3po upload-to-appstore \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--ipa-path "/full/path/Sbermarket-AppStore.ipa" \
		--auth-key-path "$SM_SCRIPTS_DIR/fastlane/AuthKey_7Z3B4S7356.p8" \
		--auth-key-issuer-id "fake issuer id" \
		--verbose
}

upload_to_firebase_1() {
	$c3po upload-to-firebase \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--ipa-path "/full/path/Sbermarket-AppStore.ipa" \
		--release-notes "fake release notes $(date)" \
		--testers-emails "tester_1@sbermarket.ru,tester_2@sbermarket.ru" \
		--testers-groups-aliases "group-1,QA-team,dev-team" \
		--firebase-token "fake firebase token" \
		--firebase-app-id "fake firebase app id" \
		--verbose
}

upload_to_firebase_2() {
	$c3po upload-to-firebase \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--ipa-path "/full/path/Sbermarket-AppStore.ipa" \
		--testers-groups-aliases "group-1,QA-team,dev-team" \
		--firebase-token "fake firebase token" \
		--firebase-app-id "fake firebase app id" \
		--verbose
}

set_provisioning() {
	$c3po set-provisioning-profile \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--scheme "fake Scheme" \
		--build-configuration "fake build config" \
		--provision-profile-name "fake provisioning profile name" \
		--verbose
}

build_scheme() {
	$c3po build \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--scheme "fake Scheme" \
		--build-configuration "fake build config" \
		--build-for-testing "false" \
		--verbose
}

archive_and_export_ipa() {
	$c3po archive-and-export-ipa \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--scheme "fake Scheme" \
		--build-configuration "fake build config" \
		--ipa-name "super-app.ipa" \
		--bundleid-provision-profile-name "some.bundle.id : c3po adhoc some.bundle.id" \
		--compile-bitcode false \
		--export-method "ad-hoc" \
		--verbose
}

set_build_number() {
	$c3po build-number set \
		--project-dir $PROJECT_DIR \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--info-plist \
		--build-settings \
		--verbose \
		6.50.199.2222222
		
	$c3po build-number set \
		--project-dir $PROJECT_DIR \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--info-plist \
		--verbose \
		""
		
	$c3po build-number set \
		--project-dir $PROJECT_DIR \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--build-settings \
		--verbose \
		1
}

change_version() {
	$c3po change-version \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/cut-release.yml" \
		--bump-major \
		--verbose
		
	$c3po change-version \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/cut-release.yml" \
		--bump-minor \
		--verbose
		
	$c3po change-version \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--config "$CONFIGS_DIR/cut-release.yml" \
		--bump-patch \
		--verbose
}

report_unused_code() {
	$c3po report-unused-code \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--reported-file "SMUIKit/Main/Resources/Images/Images.swift" \
		--scheme Sbermarket \
		--configuration Debug \
		--ignore-type-name AssetImageTypeAlias \
		--verbose
}

upload_gitlab_package() {
	$c3po upload-gitlab-package \
		$SHARED_CONFIG_OPT \
		$ONLY_VERIFY_OPT \
		--project-dir $PROJECT_DIR \
		--project-id 999999 \
		--package-name "fake_package" \
		--package-version "1.0.1" \
		--file "/fake/test_file.txt" \
		--uploaded-file-name "file.txt" \
		--timeout-seconds "600" \
		--verbose
}

# ==================================================== #

verify_all_configs () {
	guardian_initial_note

	guardian_check_author

	guardian_before_build

	qa_tests

	all_tests

	guardian_after_build

	patch_test_plan_env

	change_jira_issue_labels

	check_commits

	setup_reviewers

	setup_assignee

	check_stop_list

	setup_labels
	
	setup_certs
	update_certs
	change_certs_password

	upload_to_appstore
	upload_to_firebase_1
	upload_to_firebase_2
	
	set_provisioning

	build_scheme

	archive_and_export_ipa
	
	set_build_number

	change_version
}

# ==================================================== #

set -x

$c3po --help
$c3po --version

verify_all_configs

set +x

# ==================================================== #

echo
echo "✅✅✅"
echo
