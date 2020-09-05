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
        yield: logSuccess(git: git, branchResult: ref.get, logResult: log.get)
    )^
    
    let gitLog = [GitLogEntry(ref.get), GitLogEntry(log.get)]
    
    return .GitResult(gitLog, .GotLog(result.unsafeRunSyncEither().fold(error, identity)))
}

func logSuccess(git: Git, branchResult: ProcessResult, logResult: ProcessResult) -> AsyncData<LogInfo> {
    let branch = branchResult.output
    let log = parseCommits(git: git, logResult.output)

    return .Success(LogInfo(branch: branch, commits: log))
}
