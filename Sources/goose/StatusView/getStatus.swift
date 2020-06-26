import Bow
import BowEffects
import Foundation
import GitLib
import os.log

public enum AsyncData<T: Equatable>: Equatable {
    case loading
    case success(T)
    case error(Error)

    public static func == (lhs: AsyncData<T>, rhs: AsyncData<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true

        case let (.success(l), .success(r)):
            return l == r

        case let (.error(l), .error(r)):
            return l.localizedDescription == r.localizedDescription

        default:
            return false
        }
    }
}

extension GitCommand {
    func exec() -> Task<ProcessResult> {
        execute(process: ProcessDescription.git(self))
    }
}

func getStatus() -> Message {
    let branch = Task<String>.var()
    let tracking = Task<String>.var()
    let aheadBehind = Task<([String], [String])>.var()
    let ahead = Task<[GitCommit]>.var()
    let behind = Task<[GitCommit]>.var()
    let status = Task<GitStatus>.var()
    let log = Task<[GitCommit]>.var()
    let worktree = Task<[String: [GitHunk]]>.var()
    let index = Task<[String: [GitHunk]]>.var()

    let result = binding(
        branch <- Git.symbolicref().exec().map { $0.output },
        tracking <- Git.revparse(branch.get).exec().map { $0.output },
        aheadBehind <- Git.revlist(branch.get).exec().map(parseRevlist),
        ahead <- getAheadOrBehind(aheadBehind.get.0),
        behind <- getAheadOrBehind(aheadBehind.get.1),
        status <- Git.status().exec().flatMap(mapStatus),
        log <- Git.log(num: 10).exec().map { $0.output }.map(parseCommits),
        worktree <- Git.diff.files().exec().map(mapDiff),
        index <- Git.diff.index().exec().map(mapDiff),
        yield: statusSuccess(branch.get, tracking.get, status.get, log.get, worktree.get, index.get, ahead.get, behind.get)
    )^

    return .gotStatus(result.unsafeRunSyncEither().fold(error, identity))
}

func parseRevlist(_ revlist: ProcessResult) -> ([String], [String]) {
    let commits = revlist.output.split(regex: "\n")
    let ahead = commits.filter { $0.starts(with: "<") }.map { String($0[1...]) }
    let behind = commits.filter { $0.starts(with: ">") }.map { String($0[1...]) }
    return (ahead, behind)
}

func getAheadOrBehind(_ aheadOrBehind: [String]) -> Task<[GitCommit]> {
    aheadOrBehind.isEmpty
        ? Task.pure([])^
        : Git.show(aheadOrBehind).exec().map { $0.output }.map(parseCommits)^
}

func error<T>(error: Error) -> AsyncData<T> {
    .error(error)
}

func statusSuccess(_ branch: String, _ tracking: String, _ status: GitStatus, _ commits: [GitCommit], _ worktree: [String: [GitHunk]], _ index: [String: [GitHunk]], _ ahead: [GitCommit], _ behind: [GitCommit]) -> AsyncData<StatusInfo> {
    return .success(StatusInfo(
        branch: branch,
        tracking: tracking,
        untracked: status.changes.filter(isUntracked).map { Untracked($0.file) },
        unstaged: status.changes.filter(isUnstaged).map { Unstaged($0.file, $0.status, worktree[$0.file] ?? []) },
        staged: status.changes.filter(isStaged).map { Staged($0.file, $0.status, index[$0.file] ?? []) },
        log: commits,
        ahead: ahead,
        behind: behind
    ))
}

func addFile(files: [String]) -> Message {
    let task = execute(process: ProcessDescription.git(Git.add(files)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info(.Message($0.localizedDescription)) }, { _ in Message.commandSuccess })
}

func resetFile(files: [String]) -> Message {
    let task = execute(process: ProcessDescription.git(Git.reset(files)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info(.Message($0.localizedDescription)) }, { _ in Message.commandSuccess })
}

func apply(patch: String, reverse: Bool = false, cached: Bool = false) -> Message {
    let task = execute(process: ProcessDescription.git(Git.apply(reverse: reverse, cached: cached)), input: patch)
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info(.Message($0.localizedDescription)) }, { _ in Message.commandSuccess })
}

func restore(_ files: [String], _ staged: Bool) -> Message {
    let task = execute(process: ProcessDescription.git(Git.restore(files, staged: staged)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info(.Message($0.localizedDescription)) }, { _ in Message.commandSuccess })
}

private func mapStatus(status: ProcessResult) -> IO<Error, GitStatus> {
    parseStatus(status.output)
        .fold(IO.raiseError, IO.pure)^
}

private func mapDiff(diff: ProcessResult) -> [String: [GitHunk]] {
    let files = Git.diff.parse(diff.output).files
    return files.reduce(into: [:]) { $0[$1.source] = $1.hunks }
}
