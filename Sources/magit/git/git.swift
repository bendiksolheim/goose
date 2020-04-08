import Foundation


public struct Git {
    
    private static let git = "/usr/local/bin/git"

    static func branchName() -> ProcessDescription {
        ProcessDescription(
            workingDirectory: currentDirectory(),
            executable: git,
            arguments: ["symbolic-ref", "--short", "HEAD"]
        )
    }

    static func getCommit(_ ref: String) -> ProcessDescription {
        ProcessDescription(
            workingDirectory: currentDirectory(),
            executable: git,
            arguments: ["show", "-s", "-z", "--format=\(commitFormat)", ref]
        )
    }
    
    static func log(num: Int) -> ProcessDescription {
        ProcessDescription(
            workingDirectory: currentDirectory(),
            executable: git,
            arguments: ["log", "-n\(num)", "--format=\(commitFormat)", "-z", "--reverse"]
        )
    }
    
    static func status() -> ProcessDescription {
        ProcessDescription(
            workingDirectory: currentDirectory(),
            executable: git,
            arguments: ["status", "--porcelain=v2"]
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

private let commitFormat = [HASH, HASH_SHORT, AUTHOR_NAME, AUTHOR_EMAIL, AUTHOR_DATE, COMMITER_DATE, PARENT_HASHES, RAW_BODY].joined(separator: NEWLINE)

private func currentDirectory() -> String {
    return FileManager.default.currentDirectoryPath
}

