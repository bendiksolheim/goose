import Foundation
import GitLib
import Bow

func getCommit(_ ref: String) -> AsyncData<GitCommit> {
    let tasks = execute(process: ProcessDescription.git(Git.getCommit(ref)))
    let result = tasks.unsafeRunSyncEither()
    return result.fold(error, success)
}

private func success(commit: ProcessResult) -> AsyncData<GitCommit> {
    return .success(parseCommit(commit.output))
}
