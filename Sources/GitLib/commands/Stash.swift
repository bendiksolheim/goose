import Foundation

public struct GitStash: Equatable, Encodable {
    let path: String
    
    public func stash(_ config: StashConfig) -> GitCommand {
        let command = ["stash"] +
            (config.includeUntracked ? ["-u"] : []) +
            (config.all ? ["-u"] : [])
        return GitCommand(path, command)
    }

    public func list() -> GitCommand {
        let command = ["stash", "list"]
        return GitCommand(path, command)
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
