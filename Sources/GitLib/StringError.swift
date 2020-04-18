//
//  StringError.swift
//  magit
//
//  Created by Bendik Solheim on 05/04/2020.
//

import Foundation

public struct StringError<S: StringProtocol>: Error {
    let message: S
    
    public init(_ message: S) {
        self.message = message
    }
    
    public var localizedDescription: String {
        return String(message)
    }
}
