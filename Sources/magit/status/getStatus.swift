//
//  StatusCommand.swift
//  magit
//
//  Created by Bendik Solheim on 02/04/2020.
//

import Foundation
import BowEffects
//import Ashen
import GitLib


public enum AsyncData<T: Equatable>: Equatable {
    case loading
    case success(T)
    case error(Error)
    
    public static func == (lhs: AsyncData<T>, rhs: AsyncData<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.success(let l), .success(let r)):
            return l == r
        case (.error(let l), .error(let r)):
            return l.localizedDescription == r.localizedDescription
        default:
            return false
        }
    }
}

public struct StatusInfo: Equatable {
    let branch: String
    let changes: [Change]
    let log: [GitCommit]
}

func getStatus() -> Message {
    let tasks = IO.parZip (execute(process: ProcessDescription.git(Git.branchName())),
                           execute(process: ProcessDescription.git(Git.status())).flatMap({ result in parseStatus(result.output).fold(IO.raiseError, IO.pure) }),
                           execute(process: ProcessDescription.git(Git.log(num: 10)))
        )^
    let result = tasks.unsafeRunSyncEither()
    let status = result.fold(error, statusSuccess)
    return .gotStatus(status)
}

func error<T>(error: Error) -> AsyncData<T> {
    return .error(error)
}

func statusSuccess(branch: ProcessResult, status: GitStatus, log: ProcessResult) -> AsyncData<StatusInfo> {
    let branch = branch.output
    let log = parseCommits(log.output)
    
    return .success(StatusInfo(
        branch: branch,
        changes: status.changes,
        log: log
    ))
}
