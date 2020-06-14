import Foundation
import Bow
import os.log

public struct GitCommit: Equatable {
    public let hash: GitHash
    public let message: String
    public let parents: [String]
    public let commitDate: Date
    public let authorDate: Date
    public let author: String
    public let email: String
    public let refName: Option<String>
}

public struct GitHash: Equatable {
    public let full: String
    public let short: String
}

public func parseCommits(_ input: String) -> [GitCommit] {
    let commits = input.trimmingCharacters(in: .init(charactersIn: "\0")).split(regex: "\0")
    return commits.map(parseCommit)
}

public func parseCommit(_ commit: String) -> GitCommit {
    let lines = commit.split(separator: "\n", omittingEmptySubsequences: false);
    return GitCommit(hash: GitHash(full: String(lines[0]), short: String(lines[1])),
                  message: String(lines[7]),
                  parents: lines[6].split(separator: " ").map { parent in String(parent) },
                  commitDate: Date(timeIntervalSince1970: Double(lines[4])!),
                  authorDate: Date(timeIntervalSince1970: Double(lines[5])!),
                  author: String(lines[2]),
                  email: String(lines[3]),
                  refName: parseRefName(lines[8])
    )
}

public func parseRefName<S: StringProtocol>(_ input: S) -> Option<String> {
    if (input == "") {
        return .none()
    }
    
    let parts = String(input).split(regex: " -> ")
    return .some(parts.last!)
}

public func parseHash<S: StringProtocol>(_ input: S) -> GitHash {
    GitHash(full: String(input), short: String(input.prefix(7)))
}

public enum Area {
    case Worktree
    case Index
}

public enum FileStatus: Equatable {
    case Untracked
    case Modified
    case Deleted
    case Added
    case Renamed(String)
    case Copied
}

public struct GitChange: Equatable {
    public let area: Area
    public let status: FileStatus
    public let file: String
    
    public init(area: Area, status: FileStatus, file: String) {
        self.area = area
        self.status = status
        self.file = file
    }
}

public struct GitStatus {
    public let changes: [GitChange]
    
    public init(changes: [GitChange]) {
        self.changes = changes
    }
}

public func parseStatus(_ input: String) -> Either<Error, GitStatus> {
    let lines = input.split(separator: "\n")
    return lines
        .map(parseChange)
        .traverse { either in either }
        .map { changes in GitStatus(changes: changes.flatMap { $0 }) }^
}

public func parseChange<S: StringProtocol>(_ input: S) -> Either<Error, [GitChange]> {
    let type = input.prefix(1)
    switch type {
    case "1":
        return .right(parseOrdinaryChange(input))
        
    case "2":
        return .right(parseRenamedChange(input))
        
    case "?":
        return .right(parseUntrackedChange(input))
        
    default:
        return .left(StringError("Unknown change type: \(input)"))
    }
}

func parseOrdinaryChange<S: StringProtocol>(_ input: S) -> [GitChange] {
    var changes: [GitChange] = []
    let output = input.split(separator: " ")
    let index = String(output[1])[0]
    let worktree = String(output[1])[1]
    let file = String(output[8])
    if index == "A" {
        changes.append(GitChange(area: .Index, status: .Added, file: file))
    } else if index == "M" {
        changes.append(GitChange(area: .Index, status: .Modified, file: file))
    } else if index == "D" {
        changes.append(GitChange(area: .Index, status: .Deleted, file: file))
    }
    
    if worktree == "M" {
        changes.append(GitChange(area: .Worktree, status: .Modified, file: file))
    } else if worktree == "D" {
        changes.append(GitChange(area: .Worktree, status: .Deleted, file: file))
    }
    
    return changes
}

func parseRenamedChange<S: StringProtocol>(_ input: S) -> [GitChange] {
    var changes: [GitChange] = []
    let output = input.split(separator: " ")
    let index = String(output[1])[0]
    let worktree = String(output[1])[1]
    let files = output[9].split(separator: "\t")
    let target = String(files[0])
    let source = String(files[1])
    
    if index == "R" {
        changes.append(GitChange(area: .Index, status: .Renamed(target), file: source))
    } else if worktree == "R" {
        changes.append(GitChange(area: .Worktree, status: .Renamed(target), file: source))
    }
    
    return changes
}

func parseUntrackedChange<S: StringProtocol>(_ input: S) -> [GitChange] {
    let output = input.split(separator: " ")
    return [GitChange(area: .Worktree, status: .Untracked, file: String(output[1]))]
}
