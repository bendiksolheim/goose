import Foundation
import GitLib

public struct StatusModel: Equatable {
    let untracked: [GitChange]
    let unstaged: [GitChange]
    let staged: [GitChange]
    let log: [GitCommit]
}

public func isUntracked(_ change: GitChange) -> Bool {
    change.area == .Worktree
        && change.status == .Untracked
}

public func isUnstaged(_ change: GitChange) -> Bool {
    change.area == .Worktree
        && (change.status == .Modified
        || change.status == .Renamed
        || change.status == .Copied
        || change.status == .Deleted)
}

public func isStaged(_ change: GitChange) -> Bool {
    change.area == .Index
}
