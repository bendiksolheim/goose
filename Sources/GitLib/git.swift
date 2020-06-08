import Foundation

public struct GitCommand {
    public let arguments: [String]
}

public struct Git {
    public static func branchName() -> GitCommand {
        GitCommand(
            arguments: ["symbolic-ref", "--short", "HEAD"]
        )
    }

    public static func getCommit(_ ref: String) -> GitCommand {
        GitCommand(
            arguments: ["show", "-s", "-z", "--format=\(commitFormat)", ref]
        )
    }
    
    public static func log(num: Int) -> GitCommand {
        GitCommand(
            arguments: ["log", "-n\(num)", "--format=\(commitFormat)", "-z"]
        )
    }
    
    public static func status() -> GitCommand {
        GitCommand(
            arguments: ["status", "--porcelain=v2"]
        )
    }
    
    public static func add(_ files: [String]) -> GitCommand {
        GitCommand(
            arguments: ["add", "--"] + files
        )
    }
    
    public static func reset(_ files: [String]) -> GitCommand {
        GitCommand(
            arguments: ["reset", "--"] + files
        )
    }
    
    public static func diffFiles() -> GitCommand {
        GitCommand(
            arguments: ["diff-files", "-z", "--patch", "--no-color"]
        )
    }
    
    public static func apply(reverse: Bool = false, cached: Bool = false) -> GitCommand {
        GitCommand(
            arguments: ["apply", "--ignore-space-change"] + (reverse ? ["--reverse"] : []) + (cached ? ["--cached"] : [])
        )
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


