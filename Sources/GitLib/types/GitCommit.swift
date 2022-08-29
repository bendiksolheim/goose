import Foundation
import Bow
import os.log

public struct GitCommit: Equatable, Encodable {
    public let hash: GitHash
    public let message: String
    public let parents: [String]
    public let commitDate: Date
    public let authorDate: Date
    public let author: String
    public let email: String
    public let graph: Option<String>
    public let refName: Option<String>
    public let diff: Option<GitDiff>
}

public struct GitHash: Equatable, Encodable {
    public let full: String
    public let short: String
}

extension Option: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.description)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
}

public enum GitLogLine: Equatable, Encodable {
    case CommitLine(GitCommit)
    case GraphLine(String)
}

let graphLineRegex = #"^[/|\\-_:.* o]+$"#

public func parseLog(git: Git, _ input: String) -> [GitLogLine] {
    input.split(regex: "\n")
            .map(parseLogLine(git: git))
}

public func parseCommits(git: Git, _ input: String) -> [GitCommit] {
    input.split(regex: "\n")
            .filter { $0.range(of: graphLineRegex, options: .regularExpression) == nil }
            .map(parseCommit(git: git))
}

public func parseLogLine(git: Git) -> (String) -> GitLogLine {
    { commit in
        if commit.range(of: graphLineRegex, options: .regularExpression) != nil {
            return .GraphLine(commit)
        } else {
            return .CommitLine(parseCommit(git: git)(commit))
        }
    }
}

public func parseCommit(git: Git) -> (String) -> GitCommit {
    { commit in
        os_log("%{public}@", "Commit: \(commit.replacingOccurrences(of: "\u{200B}", with: "|"))")
            let lines = commit.split(separator: ZERO_WIDTH_SPACE, omittingEmptySubsequences: false)
            let first = String(lines[0]).match(regex: "^(?<graph>[/|\\-_:.* o]+?)?\\s*(?<hash>[a-f0-9]{40})$")
            return GitCommit(hash: GitHash(full: first["hash", default: "error"], short: String(lines[1])),
                    message: String(lines[7]),
                    parents: lines[6].split(separator: " ").map { parent in
                        String(parent)
                    },
                    commitDate: Date(timeIntervalSince1970: Double(lines[4])!),
                    authorDate: Date(timeIntervalSince1970: Double(lines[5])!),
                    author: String(lines[2]),
                    email: String(lines[3]),
                    graph: .fromOptional(first["graph"]),
                    refName: parseRefName(lines[8]),
                    diff: hasDiff(lines) ? .some(git.diff.parse(lines[9...].joined(separator: "\n"))) : .none())
        }
}

func hasDiff<S: StringProtocol>(_ lines: [S]) -> Bool {
    lines.count >= 10
            && lines[9].starts(with: "diff --git")
}

public func parseRefName<S: StringProtocol>(_ input: S) -> Option<String> {
    if input == "" {
        return .none()
    }

    let parts = String(input).split(regex: " -> ")
    return .some(parts.last!)
}

//public func parseHash<S: StringProtocol>(_ input: S) -> GitHash {
//    GitHash(full: String(input), short: String(input.prefix(7)))
//}
