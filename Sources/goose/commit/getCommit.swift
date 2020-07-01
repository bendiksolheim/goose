import Bow
import Foundation
import GitLib

func getCommit(_ ref: String) -> AsyncData<GitCommit> {
    let tasks = Git.show([ref], patch: true).exec()
    let result = tasks.unsafeRunSyncEither()
    return result.fold(error, success)
}

private func success(commit: ProcessResult) -> AsyncData<GitCommit> {
    .Success(parseCommit(commit.output))
}
