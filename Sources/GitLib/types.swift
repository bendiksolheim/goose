import Bow
import Foundation
import os.log

public func parseStat(_ input: String) -> Stats {
    let lines = input.split(regex: "\n")
    var stats: [Stat] = []
    for line in lines {
        let matches = line.match(regex: "(?<added>\\d+)\\s+(?<removed>\\d+)\\s+(?<file>.*)")
        let added = Int(matches["added", default: "0"]) ?? 0
        let removed = Int(matches["removed", default: "0"]) ?? 0
        let file = matches["file", default: "Error parsing \(line)"]
        stats.append(Stat(file: file, added: added, removed: removed))
    }

    return Stats(stats: stats)
}

public struct Stats: Equatable, Encodable {
    public let stats: [Stat]
}

public struct Stat: Equatable, Encodable {
    public let file: String
    public let added: Int
    public let removed: Int

    public func total() -> Int {
        added + removed
    }
}

public enum Area: Encodable {
    case Worktree
    case Index
}

public enum FileStatus: Equatable, Encodable {
    case Untracked
    case Modified
    case Deleted
    case Added
    case Renamed(String)
    case Copied
}

public struct GitChange: Equatable, Encodable {
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

public func parseStatus(_ input: String) -> GitStatus {
    let lines = input.split(separator: "\n")
    return GitStatus(changes: lines.flatMap(parseChange))
}

public func parseChange<S: StringProtocol>(_ input: S) -> [GitChange] {
    let type = input.prefix(1)
    switch type {
    case "1":
        return parseOrdinaryChange(input)

    case "2":
        return parseRenamedChange(input)

    default: // "?"
        return parseUntrackedChange(input)
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

public struct Stash: Equatable, Encodable {
    public let stashIndex: Int
    public let message: String

    init(_ stashIndex: Int, _ message: String) {
        self.stashIndex = stashIndex
        self.message = message
    }
}

public func parseStash(_ stashes: String) -> [Stash] {
    stashes.lines().map { line in
        let matches = line.match(regex: "stash@\\{(?<stashIndex>.*)\\}: (?<message>.*)")
        return Stash(Int(matches["stashIndex", default: "0"]) ?? 0, matches["message", default: "Error parsing \(line)"])
    }
}
