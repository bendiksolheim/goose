import Foundation

public struct Stash {
    let path: String
    
    public func stash(_ config: StashConfig) -> GitCommand {
        let command = ["stash"] +
            (config.includeUntracked ? ["-u"] : []) +
            (config.all ? ["-u"] : [])
        return GitCommand(path, command)
    }
}

public struct StashConfig {
    public let includeUntracked = false
    public let all = false
}
