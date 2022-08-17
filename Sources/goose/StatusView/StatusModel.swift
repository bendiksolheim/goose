import Foundation
import GitLib

public struct StatusModel: Equatable, Encodable {
    let info: AsyncData<StatusInfo>
    let visibility: Visibility

    func with(info: AsyncData<StatusInfo>? = nil,
              visibility: Visibility? = nil) -> StatusModel {
        StatusModel(info: info ?? self.info,
                    visibility: visibility ?? self.visibility)
    }
    
    func toggle(file: String) -> StatusModel {
        with(visibility: visibility.toggle(file: file))
    }
}

public struct Visibility: Equatable, Encodable {
    let visibility: [String: Bool]
    
    init() {
        visibility = [
            "untracked": true,
            "unstaged": true,
            "staged": true,
            "recent": false
        ]
    }
    
    private init(visibility: [String : Bool]) {
        self.visibility = visibility
    }
    
    subscript(key: String, default defaultValue: Bool) -> Bool {
        visibility[key] ?? defaultValue
    }
    
    func toggle(file: String) -> Visibility {
        let existing = visibility[file, default: false]
        return Visibility(visibility: visibility.merging([file: !existing], uniquingKeysWith: { $1 }))
    }
}

public struct Untracked: Equatable, Encodable {
    let file: String

    init(_ file: String) {
        self.file = file
    }
}

public struct Unstaged: Equatable, Encodable {
    let file: String
    let status: FileStatus
    let diff: [GitHunk]

    init(_ file: String, _ status: FileStatus, _ diff: [GitHunk]) {
        self.file = file
        self.status = status
        self.diff = diff
    }
}

public struct Staged: Equatable, Encodable {
    let file: String
    let status: FileStatus
    let diff: [GitHunk]

    init(_ file: String, _ status: FileStatus, _ diff: [GitHunk]) {
        self.file = file
        self.status = status
        self.diff = diff
    }
}

public struct StatusInfo: Equatable, Encodable {
    let branch: String
    let upstream: String
    let untracked: [Untracked]
    let unstaged: [Unstaged]
    let staged: [Staged]
    let log: [GitCommit]
    let ahead: [GitCommit]
    let behind: [GitCommit]
    let config: GitConfig
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
