import Foundation

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
