import Foundation
import GitLib

public struct StatusModel: Equatable {
    let info: AsyncData<StatusInfo>
    let visibility: [String : Bool]
    
    func copy(withInfo info: AsyncData<StatusInfo>? = nil,
              withVisibility visibility: [String : Bool]? = nil) -> StatusModel {
        StatusModel(info: info ?? self.info,
              visibility: visibility ?? self.visibility
        )
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
    
    init(_ file: String, _ status: FileStatus) {
        self.file = file
        self.status = status
    }
}

public struct Staged: Equatable {
    let file: String
    let status: FileStatus
    
    init(_ file: String, _ status: FileStatus) {
        self.file = file
        self.status = status
    }
}

public struct StatusInfo: Equatable {
    let untracked: [Untracked]
    let unstaged: [Unstaged]
    let staged: [Staged]
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
