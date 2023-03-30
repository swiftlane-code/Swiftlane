//

import Foundation
import SwiftlaneCore

// sourcery: AutoMockable
public protocol GitProtocol {
    func cloneRepo(
        url: URL,
        to path: AbsolutePath,
        from branch: String?,
        shallow: Bool
    ) throws

    func filesChangedInLastCommit(
        repo: AbsolutePath,
        onlyExistingFiles: Bool
    ) throws -> [AbsolutePath]

    func commitFileAsIsAndPush(
        repo: AbsolutePath,
        file: RelativePath,
        targetBranchName: String,
        remoteName: String,
        commitMessage: String,
        committeeName: String,
        committeeEmail: String
    ) throws

    func changedLinesInFilesInLastCommit(
        repo: AbsolutePath
    ) throws -> [String: [Int]]

    func checkCommitIsAncestorHead(
        repo: AbsolutePath,
        commit: String
    ) throws

    /// Returns name of current branch. Returns nil if not on branch (detached HEAD).
    func currentBranch(
        repo: AbsolutePath
    ) throws -> String?

    /// Fetch remotes and checkout + hard reset to a remote branch.
    func reset(
        repo: AbsolutePath,
        toBranch targetBranchName: String,
        ofRemote remoteName: String
    ) throws

    /// See `git reset --help` for detailed info and examples.
    /// - Parameters:
    ///   - mode: reset mode.
    ///   - ref: reset ref. Pass `nil` to reset to the checked out HEAD.
    func reset(
        repo: AbsolutePath,
        _ mode: GitResetOption,
        to ref: String?
    ) throws

    /// Perform a hard reset.
    func discardAllChanges(
        repo: AbsolutePath
    ) throws

    /// Fetch all remotes.
    func fetch(
        repo: AbsolutePath,
        allRemotes: Bool
    ) throws

    func branch(
        repo: AbsolutePath,
        _ options: [GitBranchOption],
        refs: [String]
    ) throws

    /// Create a new branch named `name` and start it at `startPoint`.
    /// - Parameters:
    ///   - name: name of new branch.
    ///   - startPoint: start point of new branch. Defaults to HEAD.
    ///   - resetIfExists: if a branch with name `name` already exists, then reset it to `startPoint`.
    ///   - discardLocalChanges: When switching branches, proceed even if the index or the working tree differs from HEAD.
    ///   	This is used to throw away local changes.
    func createBranch(
        repo: AbsolutePath,
        name: String,
        startPoint: String?,
        resetIfExists: Bool,
        discardLocalChanges: Bool
    ) throws

    /// This will create a new branch with no parents (`--orphan`).
    func createEmptyBranch(repo: AbsolutePath, branch: String) throws

    func remotes(repo: AbsolutePath) throws -> [String]

    func remoteBranchExists(repo: AbsolutePath, branch: String, remote: String) throws -> Bool

    func checkout(repo: AbsolutePath, ref: String, discardLocalChanges: Bool) throws

    /// Stage file(s).
    ///
    /// - Parameters:
    ///   - pattern: Files to add content from. Fileglobs (e.g.  `"*.c"`) can be given to add all matching files.
    ///     Also a leading directory name (e.g.  dir to add `dir/file1` and `dir/file2`) can be given
    ///     to update the index to match the current state of the directory as a whole
    ///     (e.g. specifying `dir` will record not just a file `dir/file1` modified in the working tree,
    ///     a file `dir/file2` added to the working tree, but also a file `dir/file3` removed from the working tree).
    ///   - force: Allow adding otherwise ignored files.
    ///   - ignoreRemoved: If you want to add modified or new files but ignore removed ones.
    ///   	Note that older versions of Git used to ignore removed files.
    func add(
        repo: AbsolutePath,
        _ pattern: String,
        force: Bool,
        ignoreRemoved: Bool
    ) throws

    /// Commit changes.
    ///
    /// - Parameters:
    ///   - message: commit message.
    ///   - userName: name of committee.
    ///   - userEmail: email of committee.
    func commit(
        repo: AbsolutePath,
        message: String,
        userName: String?,
        userEmail: String?
    ) throws

    /// Push local refs to remote.
    ///
    /// - Parameters:
    ///   - refspec:
    ///     Specify what destination ref to update with what source object.
    ///     The format of a `<refspec>` parameter is an optional plus `+`,
    ///     followed by the source object `<src>`,
    ///     followed by a colon `:`,
    ///     followed by the destination ref `<dst>`.
    ///     The special refspec `:` (or `+:` to allow non-fast-forward updates) directs Git to push "matching" branches
    ///     for every branch that exists on the local side, the remote side is updated if a branch of the same name
    ///     already exists on the remote side.
    ///   - options: options.
    func push(
        repo: AbsolutePath,
        refspec: String?,
        options: [GitPushOption]
    ) throws

    /// Fetch from and integrate with another repository or a local branch.
    ///
    /// `repo` should be the name of a remote repository.
    /// `refspec` can name an arbitrary remote ref (for example, the name of a tag)
    /// or even a collection of refs with corresponding
    /// remote-tracking branches (e.g., refs/heads/*:refs/remotes/origin/*),
    /// but usually it is the name of a branch in the remote repository.
    ///
    /// Default values for <repository> and <branch> are read
    /// from the "remote" and "merge" configuration for the current branch as set by --track.
    func pull(
        repo: AbsolutePath,
        options: [GitPullOption],
        repoOption: (String, refspec: String?)?
    ) throws
}
