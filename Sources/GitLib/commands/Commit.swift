import Foundation

public struct Commit: Equatable, Encodable {
    let path: String

    public func commit(_ args: [CommitArgs]) -> GitCommand {
        GitCommand(path, ["commit"] + args.flatMap { $0.asParam() } )
    }

    public func noVerify(_ message: String) -> GitCommand {
        GitCommand(path, ["commit", "--no-verify", "--message", message])
    }
}

public enum CommitArgs {
    case AllowEmpty
    case NoVerify
    case Message(String)

    func asParam() -> [String] {
        switch self {
        case .AllowEmpty:
            return ["--allow-empty"]
        case .NoVerify:
            return ["--no-verify"]
        case let .Message(msg):
            return ["--message", msg]
        }
    }
}