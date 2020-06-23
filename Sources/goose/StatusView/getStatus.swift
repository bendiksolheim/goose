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

func getStatus() -> Message {
    let tasks = IO.parZip(execute(process: ProcessDescription.git(Git.status())).flatMap(mapStatus),
                          execute(process: ProcessDescription.git(Git.log(num: 10))),
                          execute(process: ProcessDescription.git(Git.diff.files())),
                          execute(process: ProcessDescription.git(Git.diff.index())))^
    let result = tasks.unsafeRunSyncEither()
    let status = result.fold(error, statusSuccess)
    return .gotStatus(status)
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
