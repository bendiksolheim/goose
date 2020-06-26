import BowEffects
import Foundation
import GitLib
import os.log

public struct LogInfo: Equatable {
    let branch: String
    let commits: [GitCommit]
}

func getLog() -> Message {
    let tasks = IO.parZip(execute(process: ProcessDescription.git(Git.symbolicref())),
                          execute(process: ProcessDescription.git(Git.log(num: 100))))^
    let result = tasks.unsafeRunSyncEither()
    let log: AsyncData = result.fold(error, logSuccess)
    return .gotLog(log)
}

func logSuccess(branchResult: ProcessResult, logResult: ProcessResult) -> AsyncData<LogInfo> {
    let branch = branchResult.output
    let log = parseCommits(logResult.output)

    return .success(LogInfo(branch: branch, commits: log))
}
