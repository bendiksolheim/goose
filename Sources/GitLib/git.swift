import Foundation

public struct GitCommand {
    public let arguments: [String]

    public init(_ path: String, _ arguments: [String]) {
        self.arguments = ["-C", path] + arguments
    }
    
    public func cmd() -> String {
        (["git"] + arguments).joined(separator: " ")
    }
}

public struct Git: Equatable, Encodable {
    let path: String
    public let config: Config
    public let show: Show
    public let diff: Diff
    public let stash: GitStash
    public let log: GitLog
    public let commit: Commit
    public let reset: Reset
    
    public init(path: String) {
        self.path = path
        config = Config(path: path)
        show = Show(path: path)
        diff = Diff(path: path)
        stash = GitStash(path: path)
        log = GitLog(path: path)
        commit = Commit(path: path)
        reset = Reset(path: path)
    }
    
    public func symbolicref() -> GitCommand {
        GitCommand(path, ["symbolic-ref", "--short", "HEAD"])
    }
    
    public func revparse(_ branch: String) -> GitCommand {
        GitCommand(path, ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "\(branch)@{u}"])
    }
    
    public func revlist(_ branch: String) -> GitCommand {
        GitCommand(path, ["rev-list", "--left-right", "\(branch)...\(branch)@{u}"])
    }

    public func status() -> GitCommand {
        GitCommand(path, ["status", "--porcelain=v2"])
    }

    public func add(_ files: [String]) -> GitCommand {
        GitCommand(path, ["add", "--"] + files)
    }

    public func apply(reverse: Bool = false, cached: Bool = false) -> GitCommand {
        GitCommand(path, ["apply", "--ignore-space-change"] + (reverse ? ["--reverse"] : []) + (cached ? ["--cached"] : []))
    }
    
    public func checkout(ref: String = "HEAD", files: [String]) -> GitCommand {
        GitCommand(path, ["checkout", ref, "--"] + files)
    }
    
    public func restore(_ files: [String], staged: Bool = false) -> GitCommand {
        GitCommand(path, ["restore"] + files + (staged ? ["--staged"] : []))
    }
    
    public func push() -> GitCommand {
        GitCommand(path, ["push"])
    }
    
    public func pull() -> GitCommand {
        GitCommand(path, ["pull"])
    }
}

private let NEWLINE = "%n"
private let HASH = "%H"
private let HASH_SHORT = "%h"
private let AUTHOR_NAME = "%aN"
private let AUTHOR_EMAIL = "%aE"
private let AUTHOR_DATE = "%at"
private let COMMITER_DATE = "%ct"
private let PARENT_HASHES = "%P"
private let RAW_BODY = "%B"
private let SUBJECT = "%s"
private let REF_NAME = "%D"

let ZERO_WIDTH_SPACE: Character = "\u{200B}"

let commitFormat = [HASH, HASH_SHORT, AUTHOR_NAME, AUTHOR_EMAIL, AUTHOR_DATE, COMMITER_DATE, PARENT_HASHES, SUBJECT, REF_NAME].joined(separator: String(ZERO_WIDTH_SPACE))
