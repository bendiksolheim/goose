import Foundation
import BowEffects
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
        case (.success(let l), .success(let r)):
            return l == r
        case (.error(let l), .error(let r)):
            return l.localizedDescription == r.localizedDescription
        default:
            return false
        }
    }
}

func getStatus() -> Message {
    let tasks = IO.parZip (execute(process: ProcessDescription.git(Git.status())).flatMap(mapStatus),
                           execute(process: ProcessDescription.git(Git.log(num: 10))),
                           execute(process: ProcessDescription.git(DiffFiles.command()))
        )^
    let result = tasks.unsafeRunSyncEither()
    let status = result.fold(error, statusSuccess)
    return .gotStatus(status)
}

func error<T>(error: Error) -> AsyncData<T> {
    return .error(error)
}

func statusSuccess(status: GitStatus, log: ProcessResult, diff: GitDiff) -> AsyncData<StatusInfo> {
    return .success(StatusInfo(
        untracked: status.changes.filter(isUntracked).map { Untracked($0.file) },
        unstaged: status.changes.filter(isUnstaged).map { Unstaged($0.file, $0.status) },
        staged: status.changes.filter(isStaged).map { Staged($0.file, $0.status) },
        log: parseCommits(log.output)
    ))
}

func addFile(files: [String]) -> Message {
    let task = execute(process: ProcessDescription.git(Git.add(files)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info($0.localizedDescription) }, { _ in Message.commandSuccess })
}

func resetFile(files: [String]) -> Message {
    let task = execute(process: ProcessDescription.git(Git.reset(files)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info($0.localizedDescription) }, { _ in Message.commandSuccess})
}

private func mapStatus(status: ProcessResult) -> IO<Error, GitStatus> {
    parseStatus(status.output)
        .fold(IO.raiseError, IO.pure)^
}

private func mapDiff(diff: ProcessResult) -> IO<Error, GitDiff> {
    return DiffFiles.parse(diff.output)
        .fold(IO.raiseError, IO.pure)^
}
