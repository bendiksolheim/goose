import Bow
import BowEffects
import Foundation
import GitLib


func getDiff(git: Git, _ ref: String) -> Message {
    let commit = Task<ProcessResult>.var()
    let stats = Task<ProcessResult>.var()
    let tasks = binding(
        commit <- git.show.patch([ref]).exec(),
        stats <- git.show.stat(ref).exec(),
        yield: commitSuccess(git: git, commit.get, stats.get)
    )^
    
    return runAndMap(tasks) { .GotCommit(ref, $0) }
}

private func commitSuccess(git: Git, _ commit: ProcessResult, _ stats: ProcessResult) -> GitLogAndResult<AsyncData<CommitInfo>> {
    GitLogAndResult(
        [commit, stats].map { GitLogEntry($0) },
        .Success(CommitInfo(commit: parseCommit(git: git)(commit.output), stats: parseStat(stats.output)))
    )
}
