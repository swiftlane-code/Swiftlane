//

import Foundation

/// See: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
public enum GitLabCIEnvironmentVariable: String {
    // MARK: - Predefined variables for all pipelines

    /// The commit branch name.
    /// Available in branch pipelines, including pipelines for the default branch.
    /// Not available in merge request pipelines or tag pipelines.
    case CI_COMMIT_BRANCH

    /// The description of the commit.
    /// If the title is shorter than 100 characters, the message without the first line.
    case CI_COMMIT_DESCRIPTION

    /// The full commit message.
    case CI_COMMIT_MESSAGE

    /// The branch or tag name for which project is built.
    case CI_COMMIT_REF_NAME

    /// The commit revision the project is built for.
    case CI_COMMIT_SHA

    /// The first eight characters of CI_COMMIT_SHA.
    case CI_COMMIT_SHORT_SHA

    /// The timestamp of the commit in the ISO 8601 format.
    case CI_COMMIT_TIMESTAMP

    /// The title of the commit. The full first line of the message.
    case CI_COMMIT_TITLE

    /// The internal ID of the job, unique across all jobs in the GitLab instance.
    case CI_JOB_ID

    /// true if a job was started manually.
    case CI_JOB_MANUAL

    /// The name of the job.
    case CI_JOB_NAME

    /// The name of the job’s stage.
    case CI_JOB_STAGE

    /// The status of the job as each runner stage is executed.
    /// Use with after_script. Can be success, failed, or canceled.
    case CI_JOB_STATUS

    /// The job details URL.
    case CI_JOB_URL

    /// The UTC datetime when a job started, in ISO 8601 format.
    case CI_JOB_STARTED_AT

    /// The instance-level ID of the current pipeline. This ID is unique across all projects on the GitLab instance.
    case CI_PIPELINE_ID

    /// The project-level IID (internal ID) of the current pipeline. This ID is unique only within the current project.
    case CI_PIPELINE_IID

    /// How the pipeline was triggered. Can be push, web, schedule, api, external, chat, webide, merge_request_event, external_pull_request_event, parent_pipeline, trigger, or pipeline.
    case CI_PIPELINE_SOURCE

    /// The URL for the pipeline details.
    case CI_PIPELINE_URL

    /// The UTC datetime when the pipeline was created, in ISO 8601 format.
    case CI_PIPELINE_CREATED_AT

    /// The full path the repository is cloned to, and where the job runs from. If the GitLab Runner builds_dir parameter is set, this variable is set relative to the value of builds_dir. For more information, see the Advanced GitLab Runner configuration.
    case CI_PROJECT_DIR

    /// The ID of the current project. This ID is unique across all projects on the GitLab instance.
    case CI_PROJECT_ID

    /// The name of the directory for the project. For example if the project URL is gitlab.example.com/group-name/project-1, CI_PROJECT_NAME is project-1.
    case CI_PROJECT_NAME

    /// The project namespace (username or group name) of the job.
    case CI_PROJECT_NAMESPACE

    /// The project namespace with the project name included.
    case CI_PROJECT_PATH

    /// The human-readable project name as displayed in the GitLab web interface.
    case CI_PROJECT_TITLE

    /// The HTTP(S) address of the project.
    case CI_PROJECT_URL

    /// The URL to clone the Git repository.
    case CI_REPOSITORY_URL

    /// The description of the runner.
    case CI_RUNNER_DESCRIPTION

    /// The OS/architecture of the GitLab Runner executable. Might not be the same as the environment of the executor.
    case CI_RUNNER_EXECUTABLE_ARCH

    /// The unique ID of the runner being used.
    case CI_RUNNER_ID

    /// A comma-separated list of the runner tags.
    case CI_RUNNER_TAGS

    /// The version of the GitLab Runner running the job.
    case CI_RUNNER_VERSION

    /// Available for all jobs executed in CI/CD. true when available.
    case GITLAB_CI

    /// The email of the user who started the job.
    case GITLAB_USER_EMAIL

    /// The ID of the user who started the job.
    case GITLAB_USER_ID

    /// The username of the user who started the job.
    case GITLAB_USER_LOGIN

    /// The name of the user who started the job.
    case GITLAB_USER_NAME

    // MARK: - Predefined variables for merge request pipelines

    /// Approval status of the merge request. true when merge request approvals is available and the merge request has been approved.
    case CI_MERGE_REQUEST_APPROVED

    /// Comma-separated list of usernames of assignees for the merge request.
    ///
    /// Note: GitLab Documentation of values of `CI_MERGE_REQUEST_ASSIGNEES` env variable is not accurate.
    ///
    /// Really possible values are:
    /// * `kevin78, kimjason, and williammartinez`
    ///	* `kevin78 and williammartinez`
    /// * `kevin78`
    case CI_MERGE_REQUEST_ASSIGNEES

    /// The instance-level ID of the merge request. This is a unique ID across all projects on GitLab.
    case CI_MERGE_REQUEST_ID

    /// The project-level IID (internal ID) of the merge request. This ID is unique for the current project.
    case CI_MERGE_REQUEST_IID

    /// Comma-separated label names of the merge request.
    case CI_MERGE_REQUEST_LABELS

    /// The ID of the project of the merge request.
    case CI_MERGE_REQUEST_PROJECT_ID

    /// The path of the project of the merge request. For example namespace/awesome-project.
    case CI_MERGE_REQUEST_PROJECT_PATH

    /// The URL of the project of the merge request. For example, http://192.168.10.15:3000/namespace/awesome-project.
    case CI_MERGE_REQUEST_PROJECT_URL

    /// The source branch name of the merge request.
    case CI_MERGE_REQUEST_SOURCE_BRANCH_NAME

    /// The HEAD SHA of the source branch of the merge request.
    /// The variable is empty in merge request pipelines.
    /// The SHA is present only in merged results pipelines.
    case CI_MERGE_REQUEST_SOURCE_BRANCH_SHA

    /// The ID of the source project of the merge request.
    case CI_MERGE_REQUEST_SOURCE_PROJECT_ID

    /// The path of the source project of the merge request.
    case CI_MERGE_REQUEST_SOURCE_PROJECT_PATH

    /// The URL of the source project of the merge request.
    case CI_MERGE_REQUEST_SOURCE_PROJECT_URL

    /// The target branch name of the merge request.
    case CI_MERGE_REQUEST_TARGET_BRANCH_NAME

    /// The HEAD SHA of the target branch of the merge request.
    /// The variable is empty in merge request pipelines.
    /// The SHA is present only in merged results pipelines.
    case CI_MERGE_REQUEST_TARGET_BRANCH_SHA

    /// The title of the merge request.
    case CI_MERGE_REQUEST_TITLE

    /// The event type of the merge request. Can be detached, merged_result or merge_train.
    case CI_MERGE_REQUEST_EVENT_TYPE

    /// The version of the merge request diff.
    case CI_MERGE_REQUEST_DIFF_ID

    /// The base SHA of the merge request diff.
    case CI_MERGE_REQUEST_DIFF_BASE_SHA
}
