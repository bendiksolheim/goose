//
//  LogCommand.swift
//  magit
//
//  Created by Bendik Solheim on 10/04/2020.
//

import Foundation
//import Ashen
import BowEffects
import GitLib

public struct LogInfo {
    let branch: String
    let commits: [GitCommit]
}

/*public class Log: Command {
    
    public typealias OnResult = (AsyncData<LogInfo>) -> AnyMessage
    
    let onResult: OnResult
    
    init(onResult: @escaping OnResult) {
        self.onResult = onResult
    }

    public func start(_ send: @escaping (AnyMessage) -> Void) {
        let tasks = IO.parZip(execute(process: ProcessDescription.git(Git.branchName())),
                              execute(process: ProcessDescription.git(Git.log(num: 100))))^
        let result = tasks.unsafeRunSyncEither()
        let log: AsyncData = result.fold(error, success)
        let message = onResult(log)
        send(message)
    }

    func error(error: Error) -> AsyncData<LogInfo> {
        return .error(error)
    }

    func success(branchResult: ProcessResult, logResult: ProcessResult) -> AsyncData<LogInfo> {
        let branch = branchResult.output
        let log = parseCommits(logResult.output)

        return .success(LogInfo(branch: branch, commits: log))
    }
}
*/
