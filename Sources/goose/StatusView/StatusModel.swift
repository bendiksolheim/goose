import Foundation
import GitLib

public struct StatusModel: Equatable {
    let info: AsyncData<StatusInfo>
    let visibility: [String: Bool]

    func with(info: AsyncData<StatusInfo>? = nil,
              visibility: [String: Bool]? = nil) -> StatusModel {
        StatusModel(info: info ?? self.info,
                    visibility: visibility ?? self.visibility)
    }
}

public struct Untracked: Equatable {
    let file: String

    init(_ file: String) {
        self.file = file
    }
}

public struct Unstaged: Equatable {
    let file: String
    let status: FileStatus
    let diff: [GitHunk]

    init(_ file: String, _ status: FileStatus, _ diff: [GitHunk]) {
        self.file = file
        self.status = status
        self.diff = diff
    }
}

public struct Staged: Equatable {
    let file: String
    let status: FileStatus
    let diff: [GitHunk]

    init(_ file: String, _ status: FileStatus, _ diff: [GitHunk]) {
        self.file = file
        self.status = status
        self.diff = diff
    }
}

public struct StatusInfo: Equatable {
    let branch: String
    let tracking: String
    let untracked: [Untracked]
    let unstaged: [Unstaged]
    let staged: [Staged]
    let log: [GitCommit]
    let ahead: [GitCommit]
    let behind: [GitCommit]
}

public func isUntracked(_ change: GitChange) -> Bool {
    change.area == .Worktree
        && change.status == .Untracked
}

public func isUnstaged(_ change: GitChange) -> Bool {
    change.area == .Worktree
        && (change.status == .Modified
            || isRenamed(change.status)
            || change.status == .Copied
            || change.status == .Deleted)
}

func isRenamed(_ change: FileStatus) -> Bool {
    if case .Renamed = change {
        return true
    } else {
        return false
    }
}

public func isStaged(_ change: GitChange) -> Bool {
    change.area == .Index
}
