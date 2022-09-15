import Foundation

public struct Reset: Encodable, Equatable {
    let path: String

    public func reset(_ files: [String]) -> GitCommand {
        GitCommand(path, ["reset", "--"] + files)
    }

    public func soft(_ commit: String) -> GitCommand {
        GitCommand(path, ["reset", "--soft", commit])
    }
}