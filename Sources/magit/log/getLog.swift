//
//  LogCommand.swift
//  magit
//
//  Created by Bendik Solheim on 10/04/2020.
//

import Foundation
import BowEffects
import GitLib

public struct LogInfo: Equatable {
    let branch: String
    let commits: [GitCommit]
}

func getLog() -> Message {
    let tasks = IO.parZip(execute(process: ProcessDescription.git(Git.branchName())),
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
