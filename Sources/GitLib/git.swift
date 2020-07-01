import Foundation

public struct GitCommand {
    public let arguments: [String]

    public init(_ arguments: [String]) {
        self.arguments = arguments
    }
}

public struct Git {
    public static func symbolicref() -> GitCommand {
        GitCommand(["symbolic-ref", "--short", "HEAD"])
    }
    
    public static func revparse(_ branch: String) -> GitCommand {
        GitCommand(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "\(branch)@{u}"])
    }
    
    public static func revlist(_ branch: String) -> GitCommand {
        GitCommand(["rev-list", "--left-right", "\(branch)...\(branch)@{u}"])
    }
    
    public static func show(_ ref: [String], patch: Bool = false) -> GitCommand {
        GitCommand(["show", "-s", "-z", "--format=\(commitFormat)"] + ref + (patch ? ["-p"] : []))
    }

    public static func log(num: Int) -> GitCommand {
        GitCommand(["log", "-n\(num)", "--format=\(commitFormat)", "-z"])
    }

    public static func status() -> GitCommand {
        GitCommand(["status", "--porcelain=v2"])
    }

    public static func add(_ files: [String]) -> GitCommand {
        GitCommand(["add", "--"] + files)
    }

    public static func reset(_ files: [String]) -> GitCommand {
        GitCommand(["reset", "--"] + files)
    }

    public static func apply(reverse: Bool = false, cached: Bool = false) -> GitCommand {
        GitCommand(["apply", "--ignore-space-change"] + (reverse ? ["--reverse"] : []) + (cached ? ["--cached"] : []))
    }
    
    public static func checkout(ref: String = "HEAD", files: [String]) -> GitCommand {
        GitCommand(["checkout", ref, "--"] + files)
    }
    
    public static func restore(_ files: [String], staged: Bool = false) -> GitCommand {
        GitCommand(["restore"] + files + (staged ? ["--staged"] : []))
    }
    
    public static func push() -> GitCommand {
        GitCommand(["push"])
    }

    public struct diff {
        public static func files() -> GitCommand {
            GitCommand(["diff-files", "--patch", "--no-color"])
        }

        public static func index() -> GitCommand {
            GitCommand(["diff-index", "--cached", "--patch", "--no-color", "HEAD"])
        }

        public static func parse(_ input: String) -> GitDiff {
            let diff = internalParse(input)
            return GitDiff(diff.files.map { filename, file in
                GitFile(filename, file.hunks.map { _, hunk in
                    GitHunk(hunk.lines, hunk.patch.joined(separator: "\n") + "\n")
                })
            })
        }
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
