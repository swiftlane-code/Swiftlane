//

import Foundation

public enum GitPullOption: Hashable, CustomStringConvertible {
    /// Fetch all remotes.
    case all

    /// Rebase instead of merge if unpushed commits exist.
    case rebase(RebaseVariant)

    public enum RebaseVariant: String, Hashable {
        /// When false, merge the current branch into the upstream branch.
        case `false`

        /// When true, rebase the current branch on top of the upstream branch after fetching.
        /// If there is a remote-tracking branch corresponding to the upstream branch
        /// and the upstream branch was rebased since last fetched, the rebase
        /// uses that information to avoid rebasing non-local changes.
        case `true`

        /// When set to merges, rebase using git rebase --rebase-merges
        /// so that the local merge commits are included in the rebase.
        case merges

        /// When set to preserve (deprecated in favor of merges), rebase with
        /// the --preserve-merges option passed to git rebase so that locally created merge commits will not be flattened.
        case preserve

        /// When interactive, enable the interactive mode of rebase.
        // case interactive
    }

    public var description: String {
        switch self {
        case .all:
            return "--all"
        case let .rebase(variant):
            return "--rebase=" + variant.rawValue
        }
    }
}
