//

import Foundation

public enum GitResetOption: String, Codable, Hashable {
    /// Does not touch the index file or the working tree at all (but resets the head to `<commit>`, just like all modes do).
    /// This leaves all your changed files "Changes to be committed", as git status would put it.
    case soft

    /// Resets the index but not the working tree (i.e., the changed files are preserved but not marked for commit)
    /// and reports what has not been updated.
    /// If -N is specified, removed paths are marked as intent-to-add.
    case mixed

    /// Resets the index and working tree. Any changes to tracked files in the working tree since `<commit>` are discarded.
    case hard

    /// Resets the index and updates the files in the working tree that are different between `<commit>` and `HEAD`,
    /// but keeps those which are different between the index and working tree (i.e. which have changes which have not been added).
    /// If a file that is different between `<commit>` and the index has unstaged changes, reset is aborted.
    /// In other words, `merge` does something like a git `read-tree -u -m <commit>`, but carries forward unmerged index entries.
    case merge

    /// Resets index entries and updates files in the working tree that are different between `<commit>` and `HEAD`.
    /// If a file that is different between `<commit>` and `HEAD` has local changes, reset is aborted.
    case keep

    /// When the working tree is updated, using `recurse-submodules` will also recursively reset
    /// the working tree of all active submodules according to the commit recorded in the superproject,
    /// also setting the submodules' HEAD to be detached at that commit.
    case recurseSubmodules = "recurse-submodules"

    case noRecurseSubmodules = "no-recurse-submodules"
}
