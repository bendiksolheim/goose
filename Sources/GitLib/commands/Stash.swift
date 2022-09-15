import Foundation

public struct GitStash: Equatable, Encodable {
    let path: String
    
    public func stash(_ config: StashConfig) -> GitCommand {
        let command = ["stash"] +
            (config.includeUntracked ? ["-u"] : []) +
            (config.all ? ["-a"] : [])
        return GitCommand(path, command)
    }

    public func push(type parameter: StashParameter? = nil, message: String? = nil) -> GitCommand {
        let command = ["stash", "push"] +
                (parameter.map { [$0.asParam()] } ?? []) +
                (message.map { ["--message", $0] } ?? [])
        return GitCommand(path, command)
    }

    public func apply() -> GitCommand {
        GitCommand(path, ["stash", "apply"])
    }

    public func pop() -> GitCommand {
        GitCommand(path, ["stash", "pop"])
    }

    public func list() -> GitCommand {
        let command = ["stash", "list"]
        return GitCommand(path, command)
    }
}



public enum StashParameter: String {
    case Staged = "--staged"
    case All = "--all"
    case IncludeUntracked = "--include-untracked"

    func asParam() -> String {
        rawValue
    }
}

public struct StashConfig {
    public let includeUntracked: Bool
    public let all: Bool

    public init(includeUntracked: Bool = false, all: Bool = false) {
        self.includeUntracked = includeUntracked
        self.all = all
    }
}
