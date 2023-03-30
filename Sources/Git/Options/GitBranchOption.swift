//

import Foundation

public enum GitBranchOption: Hashable, CustomStringConvertible {
    /// Delete a branch. The branch must be fully merged in its upstream branch, or in HEAD if no upstream was set with --track or --set-upstream-to.
    case delete

    /// Reset <branchname> to <startpoint>, even if <branchname> exists already. Without -f, git branch refuses to change an existing branch. In combination with -d (or --delete), allow deleting the branch irrespective of its merged status. In combination with -m (or --move), allow renaming the branch even if the new branch name already exists, the same applies for -c (or --copy).
    case force

    /// Move/rename a branch and the corresponding reflog.
    case move

    /// Copy a branch and the corresponding reflog.
    case copy

    /// Sorting and filtering branches are case insensitive.
    case ignoreCase

    /// List both remote-tracking branches and local branches. Combine with --list to match optional pattern(s).
    case all

    /// List branches. With optional <pattern>..., e.g.  git branch --list 'maint-*', list only the branches that match the pattern(s).
    case list

    /// List or delete (if used with -d) the remote-tracking branches. Combine with --list to match the optional pattern(s).
    case remotes

    /// Print the name of the current branch. In detached HEAD state, nothing is printed.
    case showCurrent

    /// When creating a new branch, set up branch.<name>.remote and branch.<name>.merge configuration entries to mark the start-point branch as "upstream" from the new branch. This configuration will tell git to show the relationship between the two branches in git status and git branch -v. Furthermore, it directs git pull without arguments to pull from the upstream when the new branch is checked out.
    ///
    /// This behavior is the default when the start point is a remote-tracking branch. Set the branch.autoSetupMerge configuration variable to false if you want git switch, git checkout and git branch to always behave as if --no-track were given. Set it to always if you want this behavior when the start-point is either a local or remote-tracking branch.
    case track

    /// Do not set up "upstream" configuration, even if the branch.autoSetupMerge configuration variable is true.
    case noTrack

    /// As this option had confusing syntax, it is no longer supported. Please use --track or --set-upstream-to instead.
    case setUpstream

    /// Remove the upstream information for <branchname>. If no branch is specified it defaults to the current branch.
    case unsetUpstream

    case setUpstreamTo(upstream: String)

    /// Only list branches which contain the specified commit (HEAD if not specified). Implies --list.
    case contains(commit: String)

    /// Only list branches which don't contain the specified commit (HEAD if not specified). Implies --list.
    case noContains(commit: String)

    /// Only list branches whose tips are reachable from the specified commit (HEAD if not specified). Implies --list.
    case merged(commit: String)

    /// Only list branches whose tips are not reachable from the specified commit (HEAD if not specified). Implies --list.
    case noMerged(commit: String)

    ///  Sort based on the key given. Prefix - to sort in descending order of the value. You may use the --sort=<key> option multiple times, in which case the last key becomes the primary key. The keys supported are the same as those in git for-each-ref. Sort order defaults to the value configured for the branch.sort variable if exists, or to sorting based on the full refname (including refs/...  prefix). This lists detached HEAD (if present) first, then local branches and finally remote-tracking branches. See git-config(1).
    case sort(key: String)

    /// Only list branches of the given object.
    case pointsAt(obj: String)

    /// A string that interpolates %(fieldname) from a branch ref being shown and the object it points at. The format is the same as that of git-for-each-ref.
    case format(format: String)

    public var description: String {
        switch self {
        case .delete:
            return "--delete"
        case .force:
            return "--force"
        case .move:
            return "--move"
        case .copy:
            return "--copy"
        case .ignoreCase:
            return "--ignore-case"
        case .all:
            return "--all"
        case .list:
            return "--list"
        case .remotes:
            return "--remotes"
        case .showCurrent:
            return "--show-current"
        case .track:
            return "--track"
        case .noTrack:
            return "--no-track"
        case .setUpstream:
            return "--set-upstream"
        case .unsetUpstream:
            return "--unset-upstream"
        case let .setUpstreamTo(upstream):
            return "--set-upstream-to=" + upstream
        case let .contains(commit):
            return "--contains " + commit
        case let .noContains(commit):
            return "--no-contains " + commit
        case let .merged(commit):
            return "--merged " + commit
        case let .noMerged(commit):
            return "--no-merged " + commit
        case let .sort(key):
            return "--sort " + key
        case let .pointsAt(obj):
            return "--points-at " + obj
        case let .format(format):
            return "--format " + format
        }
    }
}
