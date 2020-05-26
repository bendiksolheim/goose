import Bow
import Foundation
import os.log

public struct Diff {
    public static func command() -> GitCommand {
        GitCommand(
            arguments: ["diff-files", "--patch", "--no-color"]
        )
    }
    
    public static func parse(_ input: String) -> GitDiff {
        let diff = internalParse(input)
        return GitDiff(diff.files.map { filename, file in
            return GitFile(filename, file.hunks.map { hunkname, hunk in
                GitHunk(hunk.lines, hunk.patch.joined(separator: "\n") + "\n")
            })
        })
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
            diff[currentFile].header.append(line)
        } else if line.starts(with: "deleted file mode") {
            diff[currentFile].header.append(line)
        } else if line.starts(with: "new file mode") {
            diff[currentFile].header.append(line)
        } else if line.starts(with: "rename to") {
            diff[currentFile].header.append(line)
        } else if line.starts(with: "index ") {
            diff[currentFile].header.append(line)
        } else if line.starts(with: "--- a/") {
            diff[currentFile].header.append(line)
        } else if line.starts(with: "+++ b/") {
            diff[currentFile].header.append(line)
        } else if line.starts(with: "@@ ") {
            currentHunk = line
            diff[currentFile].add(hunk: currentHunk)
        } else if line.starts(with: " ") {
            diff[currentFile][currentHunk].append(line: line)
        } else if line.starts(with: "+") {
            diff[currentFile][currentHunk].append(line: line)
        } else if line.starts(with: "-") {
            diff[currentFile][currentHunk].append(line: line)
        }
    }
    return diff
}

public class GHunk: CustomStringConvertible {
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
        return patch.joined(separator: "\n")
    }
}

public class GFile: CustomStringConvertible {
    var header: [String] = []
    var hunks: [String: GHunk] = [:]
    
    subscript(key: String) -> GHunk {
        get {
            hunks[key]!
        }
    }
    
    func add(hunk: String) {
        hunks[hunk] = GHunk(hunk, self)
    }
    
    public var description: String {
        return hunks.map { $0.value.description }.joined(separator: "\n\n")
    }
}

public class GDiff: CustomStringConvertible {
    var files: [String: GFile] = [:]
    
    subscript(key: String) -> GFile {
        get {
            files[key]!
        }
    }
    
    func add(file: String) {
        files[file] = GFile()
    }
    
    public var description: String {
        return files.map { $0.value.description }.joined(separator: "\n\n")
    }
}

extension NSString {
    public func match(regex regexString: String) -> [String: String] {
        let string = self as String
        guard let nameRegex = try? NSRegularExpression(pattern: "\\(\\?\\<(\\w+)\\>", options: []) else { return [:] }
        let nameMatches = nameRegex.matches(in: regexString, options: [], range: NSMakeRange(0, regexString.count))
        let names = nameMatches.map { (textCheckingResult) -> String in
            return (regexString as NSString).substring(with: textCheckingResult.range(at: 1))
        }
        guard let regex = try? NSRegularExpression(pattern: regexString, options: []) else { return [:] }
        let result = regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count))
        var dict = [String: String]()
        for name in names {
            if let range = result?.range(withName: name),
                range.location != NSNotFound
            {
                dict[name] = self.substring(with: range)
            }
        }
        return dict.count > 0 ? dict : [:]
    }
}
