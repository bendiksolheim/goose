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
