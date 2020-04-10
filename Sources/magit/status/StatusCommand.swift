//
//  StatusCommand.swift
//  magit
//
//  Created by Bendik Solheim on 02/04/2020.
//

import Foundation
import BowEffects
import Ashen
import GitLib

public enum AsyncData<T> {
    case loading
    case success(T)
    case error(Error)
}

public struct StatusInfo {
    let branch: String
    let changes: [Change]
    let log: [GitCommit]
}

public class Status: Command {
    
    public typealias OnResult = (AsyncData<StatusInfo>) -> AnyMessage
    
    let onResult: OnResult
    
    init(onResult: @escaping OnResult) {
        self.onResult = onResult
    }
    
    public func start(_ send: @escaping (AnyMessage) -> Void) {
        let tasks = IO.parZip (execute(process: ProcessDescription.git(Git.branchName())),
                               execute(process: ProcessDescription.git(Git.status())).flatMap({ result in parseStatus(result.output).fold(IO.raiseError, IO.pure) }),
                               execute(process: ProcessDescription.git(Git.log(num: 10)))
            )^
        let result = tasks.unsafeRunSyncEither()
        let status: AsyncData = result.fold(self.error, self.success)
        let message = self.onResult(status)
        send(message)
    }
    
    func error(error: Error) -> AsyncData<StatusInfo> {
        return .error(error)
    }
    
    func success(branch: ProcessResult, status: GitStatus, log: ProcessResult) -> AsyncData<StatusInfo> {
        let branch = branch.output
        let log = parseCommits(log.output)
        
        return .success(StatusInfo(
            branch: branch,
            changes: status.changes,
            log: log
        ))
    }
}
