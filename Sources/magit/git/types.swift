import Foundation
import Bow
import os.log

struct GitCommit {
    let hash: GitHash
    let message: String
    let parents: [String]
    let commitDate: Date
    let authorDate: Date
    let author: String
    let email: String
    let refName: Option<String>
}

struct GitHash {
    let full: String
    let short: String
}

func parseCommits(_ input: String) -> [GitCommit] {
    let commits = input.trimmingCharacters(in: .init(charactersIn: "\0")).split(regex: "\0")
    return commits.map({ commit in
        let lines = commit.split(separator: "\n", omittingEmptySubsequences: false);
        os_log("%{public}d", lines.count)
        return GitCommit(hash: GitHash(full: String(lines[0]), short: String(lines[1])),
                      message: String(lines[7]),
                      parents: lines[6].split(separator: " ").map { parent in String(parent) },
                      commitDate: Date(timeIntervalSince1970: Double(lines[4])!),
                      authorDate: Date(timeIntervalSince1970: Double(lines[5])!),
                      author: String(lines[2]),
                      email: String(lines[3]),
                      refName: parseRefName(lines[8])
        )
    })
}

func parseRefName<S: StringProtocol>(_ input: S) -> Option<String> {
    if (input == "") {
        return .none()
    }
    
    let parts = String(input).split(regex: " -> ")
    if parts.count < 2 {
        return .none()
    } else {
        return .some(parts[1])
    }
}

func parseHash<S: StringProtocol>(_ input: S) -> GitHash {
    GitHash(full: String(input), short: String(input.prefix(7)))
}

enum Area {
    case Worktree
    case Index
}

enum FileStatus {
    case Untracked
    case Modified
    case Deleted
    case Added
    case Renamed
    case Copied
}

struct Change {
    let area: Area
    let status: FileStatus
    let file: String
}

struct GitStatus {
    let changes: [Change]
}

func parseStatus(_ input: String) -> Either<Error, GitStatus> {
    let lines = input.split(separator: "\n")
    return lines
        .map(parseChange)
        .traverse { either in either }
        .map { changes in GitStatus(changes: changes.flatMap { $0 }) }^
}

func parseChange<S: StringProtocol>(_ input: S) -> Either<Error, [Change]> {
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

func parseOrdinaryChange<S: StringProtocol>(_ input: S) -> [Change] {
    var changes: [Change] = []
    let output = input.split(separator: " ")
    let index = String(output[1])[0]
    let worktree = String(output[1])[1]
    let file = String(output[8])
    if index == "A" {
        changes.append(Change(area: .Index, status: .Added, file: file))
    } else if index == "M" {
        changes.append(Change(area: .Index, status: .Modified, file: file))
    } else if index == "D" {
        changes.append(Change(area: .Index, status: .Deleted, file: file))
    }
    
    if worktree == "M" {
        changes.append(Change(area: .Worktree, status: .Modified, file: file))
    } else {
        changes.append(Change(area: .Worktree, status: .Deleted, file: file))
    }
    
    return changes
}

func parseRenamedChange<S: StringProtocol>(_ input: S) -> [Change] {
    return []
}

func parseUntrackedChange<S: StringProtocol>(_ input: S) -> [Change] {
    let output = input.split(separator: " ")
    return [Change(area: .Worktree, status: .Untracked, file: String(output[1]))]
}

func isUntracked(_ change: Change) -> Bool {
    change.area == .Worktree
        && change.status == .Untracked
}

func isUnstaged(_ change: Change) -> Bool {
    change.area == .Worktree
        && (change.status == .Modified
        || change.status == .Renamed
        || change.status == .Copied
        || change.status == .Deleted)
}

func isStaged(_ change: Change) -> Bool {
    change.area == .Index
}
