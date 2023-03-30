//

import Foundation
import SwiftlaneCore

public class Git {
    let shell: ShellExecuting
    let filesManager: FSManaging
    let diffParser: GitDiffParsing

    public init(
        shell: ShellExecuting,
        filesManager: FSManaging,
        diffParser: GitDiffParsing
    ) {
        self.shell = shell
        self.filesManager = filesManager
        self.diffParser = diffParser
    }

    private func git(_ repo: AbsolutePath?) -> String {
        (repo.map { "cd '\($0)' && " } ?? "") + "GIT_TERMINAL_PROMPT=0 git "
    }
}

extension Git: GitProtocol {
    public func filesChangedInLastCommit(
        repo: AbsolutePath,
        onlyExistingFiles: Bool
    ) throws -> [AbsolutePath] {
        try shell.run(git(repo) + "diff --name-only HEAD~1", log: .commandAndOutput(outputLogLevel: .debug))
            .stdoutText
            .unwrap()
            .split(separator: "\n")
            .map { try! RelativePath($0) }
            .map { repo.appending(path: $0) }
            .filter { !onlyExistingFiles || filesManager.fileExists($0) }
    }

    public func reset(
        repo: AbsolutePath,
        toBranch targetBranchName: String,
        ofRemote remoteName: String
    ) throws {
        let remoteBranchName = remoteName.appendingPathComponent(targetBranchName)
        try reset(repo: repo, .hard, to: nil)
        try fetch(repo: repo, allRemotes: false)
        try createBranch(
            repo: repo,
            name: targetBranchName,
            startPoint: remoteBranchName,
            resetIfExists: true,
            discardLocalChanges: true
        )
    }

    public func commitFileAsIsAndPush(
        repo: AbsolutePath,
        file: RelativePath,
        targetBranchName: String,
        remoteName: String,
        commitMessage: String,
        committeeName: String,
        committeeEmail: String
    ) throws {
        let tempFileName = try! RelativePath(UUID().uuidString)
        let originalPath = repo.appending(path: file)
        let tempPath = repo.appending(path: tempFileName)
        try filesManager.move(originalPath, newPath: tempPath)

        try reset(repo: repo, toBranch: targetBranchName, ofRemote: remoteName)

        try filesManager.delete(originalPath)
        try filesManager.move(tempPath, newPath: originalPath)
        try add(repo: repo, file.string, force: true, ignoreRemoved: false)
        try commit(repo: repo, message: commitMessage, userName: committeeName, userEmail: committeeEmail)
        try push(repo: repo, refspec: remoteName, options: [.repo(remoteName), .setUpstream])
    }

    public func changedLinesInFilesInLastCommit(
        repo: AbsolutePath
    ) throws -> [String: [Int]] {
        let diff = try shell.run(git(repo) + "diff HEAD~1", log: .commandAndOutput(outputLogLevel: .debug))
            .stdoutText
            .unwrap(errorDescription: "git output is nil")

        let changes = try diffParser.parseGitDiff(diff, ignoreFormatErrors: true)

        return changes.reduce(into: [:]) { partialResult, fileChanges in
            guard let newPath = fileChanges.newPath?.string else { return }

            partialResult[newPath] = fileChanges.addedLineNumbers.map { Int($0) }
        }
    }

    public func checkCommitIsAncestorHead(
        repo: AbsolutePath,
        commit: String
    ) throws {
        try shell.run(
            git(repo) + "merge-base --is-ancestor \(commit) HEAD",
            log: .commandAndOutput(outputLogLevel: .info)
        )
    }

    public func cloneRepo(
        url: URL,
        to path: AbsolutePath,
        from branch: String? = nil,
        shallow: Bool = false
    ) throws {
        try shell.run([
            git(nil) + "clone",
            shallow ? "--progress --depth 1 --shallow-submodules" : nil,
            branch.map { "-b '\($0)'" },
            "'\(url.absoluteString)'",
            path.string.quoted,
        ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }

    /// Returns name of current branch. Returns nil if not on branch (detached HEAD).
    public func currentBranch(
        repo: AbsolutePath
    ) throws -> String? {
        /// `git branch --show-current` prints nothing when HEAD is detached.
        guard
            let result = try shell.run(
                git(repo) + "branch --show-current",
                log: .commandAndOutput(outputLogLevel: .info)
            ).stdoutText,
            !result.isEmpty
        else { return nil }
        return result
    }

    /// See `git reset --help` for detailed info and examples.
    /// - Parameters:
    ///   - mode: reset mode.
    ///   - ref: reset ref. Pass `nil` to reset to the checked out HEAD.
    public func reset(
        repo: AbsolutePath,
        _ mode: GitResetOption,
        to ref: String?
    ) throws {
        var cmd = "reset --\(mode)"
        ref.map { cmd += " " + $0.quoted }
        try shell.run(git(repo) + cmd, log: .commandAndOutput(outputLogLevel: .info))
    }

    /// Perform a hard reset.
    public func discardAllChanges(
        repo: AbsolutePath
    ) throws {
        try reset(repo: repo, .hard, to: nil)
    }

    /// Fetch all remotes.
    public func fetch(
        repo: AbsolutePath,
        allRemotes: Bool
    ) throws {
        var cmd = "fetch"
        if allRemotes { cmd += " --all" }
        try shell.run(git(repo) + cmd, log: .commandAndOutput(outputLogLevel: .info))
    }

    public func branch(
        repo: AbsolutePath,
        _ options: [GitBranchOption],
        refs: [String]
    ) throws {
        let cmd = ["branch"] + options.map(\.description) + refs
        try shell.run([git(repo)] + cmd, log: .commandAndOutput(outputLogLevel: .info))
    }

    /// Create a new branch named `name` and start it at `startPoint`.
    /// - Parameters:
    ///   - name: name of new branch.
    ///   - startPoint: start point of new branch. Defaults to HEAD.
    ///   - resetIfExists: if a branch with name `name` already exists, then reset it to `startPoint`.
    ///   - discardLocalChanges: When switching branches, proceed even if the index or the working tree differs from HEAD.
    ///   	This is used to throw away local changes.
    public func createBranch(
        repo: AbsolutePath,
        name: String,
        startPoint: String? = nil,
        resetIfExists: Bool,
        discardLocalChanges: Bool
    ) throws {
        try shell.run([
            git(repo) + "checkout",
            discardLocalChanges ? "-f" : nil,
            resetIfExists ? "-B" : "-b",
            name,
            startPoint,
        ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }

    public func createEmptyBranch(repo: AbsolutePath, branch: String) throws {
        try shell.run(
            git(repo) + "checkout --orphan '\(branch)'",
            log: .commandAndOutput(outputLogLevel: .info)
        )
    }

    public func checkout(repo: AbsolutePath, ref: String, discardLocalChanges: Bool) throws {
        try shell.run([
            git(repo) + "checkout",
            discardLocalChanges ? "-f" : nil,
            ref,
        ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }

    public func remotes(repo: AbsolutePath) throws -> [String] {
        try shell.run(
            git(repo) + "remote show",
            log: .commandAndOutput(outputLogLevel: .info)
        ).stdoutText.unwrap()
            .split(separator: "\n")
            .map(String.init)
    }

    public func remoteBranchExists(repo: AbsolutePath, branch: String, remote: String) throws -> Bool {
        try shell.run(
            git(repo) + "ls-remote --exit-code --heads '\(remote)' '\(branch)'",
            log: .commandAndOutput(outputLogLevel: .info),
            shouldIgnoreNonZeroExitCode: { output, exitCode in
                output.stdoutText == nil && exitCode == 2
            }
        ).stdoutText?.isEmpty == false
    }

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
    public func add(
        repo: AbsolutePath,
        _ pattern: String,
        force: Bool,
        ignoreRemoved: Bool
    ) throws {
        try shell.run([
            git(repo) + "add",
            force ? "--force" : nil,
            ignoreRemoved ? "--ignore-removal" : nil,
            pattern.quoted,
        ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }

    /// Commit changes.
    ///
    /// - Parameters:
    ///   - message: commit message.
    ///   - userName: name of committee.
    ///   - userEmail: email of committee.
    public func commit(
        repo: AbsolutePath,
        message: String,
        userName: String? = nil,
        userEmail: String? = nil
    ) throws {
        try shell.run([
            git(repo),
            userName.map { "-c \"user.name=\($0)\"" },
            userEmail.map { "-c \"user.email=\($0)\"" },
            "commit",
            "-m '\(message)'",
        ].compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }

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
    public func push(
        repo: AbsolutePath,
        refspec: String? = nil,
        options: [GitPushOption]
    ) throws {
        let cmd: [String?] = ["push"] + options.map(\.description) + [refspec]
        try shell.run([git(repo)] + cmd.compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }

    /// Pull repo.
    ///
    /// `repo` should be the name of a remote repository.
    /// `refspec` can name an arbitrary remote ref (for example, the name of a tag)
    /// or even a collection of refs with corresponding
    /// remote-tracking branches (e.g., refs/heads/*:refs/remotes/origin/*),
    /// but usually it is the name of a branch in the remote repository.
    ///
    /// Default values for <repository> and <branch> are read
    /// from the "remote" and "merge" configuration for the current branch as set by --track.
    public func pull(
        repo: AbsolutePath,
        options: [GitPullOption],
        repoOption: (String, refspec: String?)?
    ) throws {
        var cmd: [String?] = ["pull"] + options.map(\.description)
        repoOption.map {
            cmd.append($0.0)
            $0.1.map { cmd.append($0) }
        }
        try shell.run([git(repo)] + cmd.compactMap { $0 }, log: .commandAndOutput(outputLogLevel: .info))
    }
}
