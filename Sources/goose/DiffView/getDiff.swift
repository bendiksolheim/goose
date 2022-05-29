import Bow
import BowEffects
import Foundation
import GitLib
import Tea


func getDiff(git: Git, _ ref: String) -> Cmd<Message> {
    let commit = Task<LowLevelProcessResult>.var()
    let stats = Task<LowLevelProcessResult>.var()
    let tasks = binding(
            commit <- git.show.patch([ref]).exec(),
            stats <- git.show.stat(ref).exec(),
            yield: commitSuccess(git: git, commit.get, stats.get)
    )^

//    return runAndMap(tasks) { .GotCommit(ref, $0) }
    return Effect(tasks).perform(
            { error in .GitResult([], .GotCommit(ref, .Error(error))) },
            { success in .GitResult(success.gitLog, .GotCommit(ref, success.result)) }
    )
//    return Effect(tasks).perform(
//            { error in .GitResult([], .GotCommit(ref, .Error(error))) },
//            { success in .GitResult(success.gitLog, .GotCommit(ref, .Success(success.result))) }
//    )
}

private func commitSuccess(git: Git, _ commit: LowLevelProcessResult, _ stats: LowLevelProcessResult) -> GitLogAndResult<AsyncData<CommitInfo>> {
    GitLogAndResult(
            [commit, stats].map {
                GitLogEntry($0)
            },
            .Success(CommitInfo(commit: parseCommit(git: git)(commit.output), stats: parseStat(stats.output)))
    )
}
