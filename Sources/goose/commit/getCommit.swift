import Bow
import Foundation
import GitLib

func getCommit(_ ref: String) -> AsyncData<GitCommit> {
    let tasks = execute(process: ProcessDescription.git(Git.show(ref)))
    let result = tasks.unsafeRunSyncEither()
    return result.fold(error, success)
}

private func success(commit: ProcessResult) -> AsyncData<GitCommit> {
    .success(parseCommit(commit.output))
}
