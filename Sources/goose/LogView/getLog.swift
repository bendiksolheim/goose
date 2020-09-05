import Bow
import BowEffects
import Foundation
import GitLib

public struct LogInfo: Equatable {
    let branch: String
    let commits: [GitCommit]
}

func getLog(git: Git) -> Message {
    let ref = Task<ProcessResult>.var()
    let log = Task<ProcessResult>.var()
    let result = binding(
        ref <- git.symbolicref().exec(),
        log <- git.log(num: 100).exec(),
        yield: logSuccess(git: git, branch: ref.get, log: log.get)
    )^
    
    return runAndMap(result) { .GotLog($0) }
}

func logSuccess(git: Git, branch: ProcessResult, log: ProcessResult) -> GitLogAndResult<AsyncData<LogInfo>> {
    GitLogAndResult(
        [branch, log].map { GitLogEntry($0) },
        .Success(LogInfo(branch: branch.output, commits: parseCommits(git: git, log.output)))
    )
}
