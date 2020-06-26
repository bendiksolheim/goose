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
    let aheadBehind = Task<([String], [String])>.var()
    let status = Task<GitStatus>.var()
    let log = Task<ProcessResult>.var()
    let worktree = Task<ProcessResult>.var()
    let index = Task<ProcessResult>.var()
    
    let result = binding(
        branch <- Git.symbolicref().exec().map { $0.output },
        aheadBehind <- Git.revlist(branch.get).exec().map(parseRevlist),
        status <- Git.status().exec().flatMap(mapStatus),
        log <- Git.log(num: 10).exec(),
        worktree <- Git.diff.files().exec(),
        index <- Git.diff.index().exec(),
        yield: statusSuccess(status: status.get, log: log.get, worktree: worktree.get, index: index.get)
    )^
    
    return .gotStatus(result.unsafeRunSyncEither().fold(error, identity))
}

func parseRevlist(_ revlist: ProcessResult) -> ([String], [String]) {
    let commits = revlist.output.split(regex: "\n")
    let ahead = commits.filter { $0.starts(with: "<") }.map { String($0[1...]) }
    let behind = commits.filter { $0.starts(with: ">") }.map { String($0[1...]) }
    os_log("Ahead: %{public}@", ahead.joined(separator: ","))
    os_log("Behind: %{public}@", behind.joined(separator: ","))
    return (ahead, behind)
}

func error<T>(error: Error) -> AsyncData<T> {
    .error(error)
}

func statusSuccess(status: GitStatus, log: ProcessResult, worktree: ProcessResult, index: ProcessResult) -> AsyncData<StatusInfo> {
    let worktreeFiles = Git.diff.parse(worktree.output).files
    let worktreeFilesMap = worktreeFiles.reduce(into: [:]) { $0[$1.source] = $1.hunks }
    let indexFiles = Git.diff.parse(index.output).files
    let indexFilesMap = indexFiles.reduce(into: [:]) { $0[$1.source] = $1.hunks }
    return .success(StatusInfo(
        untracked: status.changes.filter(isUntracked).map { Untracked($0.file) },
        unstaged: status.changes.filter(isUnstaged).map { Unstaged($0.file, $0.status, worktreeFilesMap[$0.file] ?? []) },
        staged: status.changes.filter(isStaged).map { Staged($0.file, $0.status, indexFilesMap[$0.file] ?? []) },
        log: parseCommits(log.output)
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
