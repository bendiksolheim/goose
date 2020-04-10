//
//  LogCommand.swift
//  magit
//
//  Created by Bendik Solheim on 10/04/2020.
//

import Foundation
import Ashen

public struct LogInfo {
    let logs: String
}

public class Log: Command {
    
    public typealias OnResult = (AsyncData<LogInfo>) -> AnyMessage
    
    let onResult: OnResult
    
    init(onResult: @escaping OnResult) {
        self.onResult = onResult
    }
    
    public func start(_ send: @escaping (AnyMessage) -> Void) {
        let message = onResult(.success(LogInfo(logs: "Hei")))
        send(message)
    }
}
