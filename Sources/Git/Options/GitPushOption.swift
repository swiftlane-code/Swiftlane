//

import Foundation

public enum GitPushOption: Hashable, CustomStringConvertible {
    /// Push all branches (i.e. refs under `refs/heads/`); cannot be used with other `<refspec>`.
    case all

    /// All listed refs are deleted from the remote repository. This is the same as prefixing all refs with a colon.
    case delete

    /// All refs under `refs/tags` are pushed, in addition to refspecs explicitly listed on the command line.
    case tags

    /// Usually, `git push` refuses to update a remote ref that is not an ancestor of the local ref used to overwrite it.
    /// This option overrides this restriction if the current value of the remote ref is the expected value. `git push` fails otherwise.
    case forceWithLease

    /**
     **It is preferred to use `forceWithLease` instead.**

     Usually, the command refuses to update a remote ref that is not an ancestor of the local ref used to overwrite it.

     This flag disables these checks, and can cause the remote repository to lose commits; use it with care.

     Note that --force applies to all the refs that are pushed,
     hence using it with `push.default` set to matching or with multiple push destinations configured with `remote.*.push`
     may overwrite refs other than the current branch (including local refs that are strictly behind their remote counterpart).
     To force a push to only one branch, use a + in front of the refspec to push
     (e.g git `push origin +master` to force a push to the master branch).
     */
    case force

    /// The "remote" repository that is destination of a push operation.
    /// This parameter can be either a URL (see the section GIT URLS below) or the name of a remote.
    case repo(String)

    /// For every branch that is up to date or successfully pushed, add upstream (tracking) reference,
    /// used by argument-less `git pull` and other commands.
    case setUpstream

    public var description: String {
        switch self {
        case .all:
            return "--all"
        case .delete:
            return "--delete"
        case .tags:
            return "--tags"
        case .forceWithLease:
            return "--force-with-lease"
        case .force:
            return "--force"
        case let .repo(repo):
            return "--repo=" + repo
        case .setUpstream:
            return "--set-upstream"
        }
    }
}
