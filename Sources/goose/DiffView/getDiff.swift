import Bow
import BowEffects
import Foundation
import GitLib

func getDiff(_ ref: String) -> Message {
    let commit = Task<GitCommit>.var()
    let stats = Task<Stats>.var()
    let tasks = binding(
        commit <- Git.show.patch([ref]).exec().map { parseCommit($0.output) },
        stats <- Git.show.stat(ref).exec().map { parseStat($0.output) },
        yield: commitSuccess(commit.get, stats.get)
    )^
    
    return .GitResult([], .GotCommit(ref, tasks.unsafeRunSyncEither().fold(error, identity)))
}

private func commitSuccess(_ commit: GitCommit, _ stats: Stats) -> AsyncData<CommitInfo> {
    .Success(CommitInfo(commit: commit, stats: stats))
}
