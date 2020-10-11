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

public struct Git: Equatable {
    let path: String
    public let config: Config
    public let show: Show
    public let diff: Diff
    
    public init(path: String) {
        self.path = path
        config = Config(path: path)
        show = Show(path: path)
        diff = Diff(path: path)
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

    public func log(num: Int) -> GitCommand {
        GitCommand(path, ["log", "-n\(num)", "--format=\(commitFormat)", "-z"])
    }

    public func status() -> GitCommand {
        GitCommand(path, ["status", "--porcelain=v2"])
    }

    public func add(_ files: [String]) -> GitCommand {
        GitCommand(path, ["add", "--"] + files)
    }

    public func reset(_ files: [String]) -> GitCommand {
        GitCommand(path, ["reset", "--"] + files)
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

public struct Config: Equatable {
    let path: String
    
    public func all() -> GitCommand {
        GitCommand(path, ["config", "--list"])
    }
    
    public func parse(_ input: String) -> GitConfig {
        let lines = input.split(regex: "\n")
        var configs: [String: String] = [:]
        for line in lines {
            let matches = line.match(regex: "(?<key>.*)=(?<value>.*)")
            if let key = matches["key"], let value = matches["value"] {
                configs[key] = value
            }
        }
        return GitConfig(configs)
    }
}

public struct Show: Equatable {
    let path: String
    
    public func patch(_ ref: [String]) -> GitCommand {
        GitCommand(path, ["show", "-s", "-z", "--format=\(commitFormat)", "-p"] + ref)
    }
    
    public func plain(_ ref: [String]) -> GitCommand {
        GitCommand(path, ["show", "-s", "-z", "--format=\(commitFormat)"] + ref)
    }
    
    public func stat(_ ref: String) -> GitCommand {
        GitCommand(path, ["show", "--format=", "--numstat"] + [ref])
    }
}

public struct Diff: Equatable {
    let path: String
    
    public func files() -> GitCommand {
        GitCommand(path, ["diff-files", "--patch", "--no-color"])
    }

    public func index() -> GitCommand {
        GitCommand(path, ["diff-index", "--cached", "--patch", "--no-color", "HEAD"])
    }

    public func parse(_ input: String) -> GitDiff {
        let diff = internalParse(input)
        return GitDiff(diff.files.map { filename, file in
            GitFile(filename, file.mode, file.hunks.map { _, hunk in
                GitHunk(hunk.lines, hunk.patch.joined(separator: "\n") + "\n")
            })
        })
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

private let commitFormat = [HASH, HASH_SHORT, AUTHOR_NAME, AUTHOR_EMAIL, AUTHOR_DATE, COMMITER_DATE, PARENT_HASHES, SUBJECT, REF_NAME].joined(separator: NEWLINE)
