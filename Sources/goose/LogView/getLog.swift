import Bow
import BowEffects
import Foundation
import GitLib

public struct LogInfo: Equatable {
    let branch: String
    let commits: [GitCommit]
}

func getLog() -> Message {
    let ref = Task<ProcessResult>.var()
    let log = Task<ProcessResult>.var()
    let result = binding(
        ref <- Git.symbolicref().exec(),
        log <- Git.log(num: 100).exec(),
        yield: logSuccess(branchResult: ref.get, logResult: log.get)
    )^
    
    return .GitResult(.GotLog(result.unsafeRunSyncEither().fold(error, identity)))
}

func logSuccess(branchResult: ProcessResult, logResult: ProcessResult) -> AsyncData<LogInfo> {
    let branch = branchResult.output
    let log = parseCommits(logResult.output)

    return .Success(LogInfo(branch: branch, commits: log))
}
