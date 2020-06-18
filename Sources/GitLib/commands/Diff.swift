import Bow
import Foundation
import os.log

public struct Diff {
    public static func files() -> GitCommand {
        GitCommand(
            arguments: ["diff-files", "--patch", "--no-color"]
        )
    }

    public static func index() -> GitCommand {
        GitCommand(
            arguments: ["diff-index", "--cached", "--patch", "--no-color", "HEAD"]
        )
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

public enum GitAnnotation: Equatable {
    case Summary
    case Added
    case Removed
    case Context
}

public struct GitHunkLine: Equatable {
    public let annotation: GitAnnotation
    public let content: String

    init(_ line: String) {
        let first = line[0]
        switch first {
        case "@":
            annotation = .Summary
        case "+":
            annotation = .Added
        case "-":
            annotation = .Removed
        default:
            annotation = .Context
        }
        content = line
    }
}

public struct GitHunk: Equatable {
    public let patch: String
    public let lines: [GitHunkLine]

    init(_ lines: [String], _ patch: String) {
        self.lines = lines.map(GitHunkLine.init)
        self.patch = patch
    }
}

public struct GitFile: Equatable {
    public let source: String
    public let hunks: [GitHunk]

    init(_ source: String, _ hunks: [GitHunk]) {
        self.source = source
        self.hunks = hunks
    }
}

public struct GitDiff: Equatable {
    public let files: [GitFile]

    init(_ files: [GitFile]) {
        self.files = files
    }
}

private func internalParse(_ input: String) -> GDiff {
    let lines = input.split(regex: "\n")

    let diff = GDiff()
    var currentFile = ""
    var currentHunk = ""
    for line in lines {
        if line.starts(with: "diff --git") {
            let matches = line.match(regex: "diff --git a\\/(?<a>[\\w.\\/]+)\\sb\\/(?<b>[\\w.\\/]+)")
            currentFile = matches["a", default: ""]
            diff.add(file: currentFile)
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "deleted file mode") {
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "new file mode") {
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "rename to") {
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "index ") {
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "--- a/") {
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "+++ b/") {
            diff[currentFile]?.header.append(line)
        } else if line.starts(with: "@@ ") {
            currentHunk = line
            diff[currentFile]?.add(hunk: currentHunk)
        } else {
            diff[currentFile]?[currentHunk]?.append(line: line)
        }
    }
    return diff
}

private class GHunk: CustomStringConvertible {
    var patch: [String] = []
    var header: String
    var lines: [String] = []

    init(_ header: String, _ file: GFile) {
        self.header = header
        patch.append(contentsOf: file.header)
        patch.append(header)
        lines.append(header)
    }

    func append(line: String) {
        patch.append(line)
        lines.append(line)
    }

    public var description: String {
        patch.joined(separator: "\n")
    }
}

private class GFile: CustomStringConvertible {
    var header: [String] = []
    var hunks: [String: GHunk] = [:]

    subscript(key: String) -> GHunk? {
        hunks[key]
    }

    func add(hunk: String) {
        hunks[hunk] = GHunk(hunk, self)
    }

    public var description: String {
        hunks.map { $0.value.description }.joined(separator: "\n\n")
    }
}

private class GDiff: CustomStringConvertible {
    var files: [String: GFile] = [:]

    subscript(key: String) -> GFile? {
        files[key]
    }

    func add(file: String) {
        files[file] = GFile()
    }

    public var description: String {
        files.map { $0.value.description }.joined(separator: "\n\n")
    }
}

extension NSString {
    public func match(regex regexString: String) -> [String: String] {
        let string = self as String
        guard let nameRegex = try? NSRegularExpression(pattern: "\\(\\?\\<(\\w+)\\>", options: []) else { return [:] }
        let nameMatches = nameRegex.matches(in: regexString, options: [], range: NSMakeRange(0, regexString.count))
        let names = nameMatches.map { (textCheckingResult) -> String in
            (regexString as NSString).substring(with: textCheckingResult.range(at: 1))
        }
        guard let regex = try? NSRegularExpression(pattern: regexString, options: []) else { return [:] }
        let result = regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count))
        var dict = [String: String]()
        for name in names {
            if let range = result?.range(withName: name),
                range.location != NSNotFound {
                dict[name] = substring(with: range)
            }
        }
        return dict.count > 0 ? dict : [:]
    }
}
