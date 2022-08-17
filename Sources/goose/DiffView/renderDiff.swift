import Bow
import Foundation
import GitLib
import Tea
import Slowbox

func renderDiff(diff: DiffModel) -> Node {
    switch diff.commit {
    case .Loading:
        return Text("Loading...")

    case let .Error(error):
        return Text("Error: \(error.localizedDescription)")

    case let .Success(commitInfo):
        let commit = commitInfo.commit
        let view = Vertical(.Auto, .Auto) {
            Text(FormattedText("Commit \(commit.hash.short)", .White, .Blue))
            Text(FormattedText(commit.hash.full, .LightGray))
            Text("Author:     \(commit.author) \(commit.email)")
            Text("AuthorDate: \(commit.authorDate.format(commitDateFormat))")
            Text("Commit:     \(commit.author) \(commit.email)") // TODO: need to parse committer
            Text("CommitDate: \(commit.commitDate)")
            EmptyLine()
            Text("Parent      \(commit.parents[0])")
            EmptyLine()

            renderSummary(commit: commit, stats: commitInfo.stats)
            EmptyLine()

            Vertical(.Fill, .Auto) {
                commit.diff.map { diff in
                    diff.files.flatMap(renderFile)
                }.combineAll()
            }
        }
        return view
    }
}

func renderFile(_ file: GitFile) -> [Node] {
    [Text("\(file.mode.padding(toLength: 11, withPad: " ", startingAt: 0)) \(file.source)")]
        + file.hunks.flatMap { hunk in renderHunk(hunk, []) }
}

func renderSummary(commit: GitCommit, stats: Stats) -> Node {
    let insertions = stats.stats.map { $0.added }.combineAll()
    let deletions = stats.stats.map { $0.removed }.combineAll()
    let maxWidth = stats.stats.map { $0.file.count }.max() ?? 0
    return Horizontal(.Fill, .Auto) {
        Text(FormattedText(commit.message, .White, .Magenta))
        EmptyLine()
        Text("\(stats.stats.count) files changed, \(insertions) insertions(+), \(deletions) deletions(-)")
        Horizontal(.Fill, .Auto) {
            stats.stats.map { renderStat($0, maxWidth) }
        }
    }
}

func renderStat(_ stat: Stat, _ width: Int) -> Node {
    Text(
        FormattedText(stat.file.padding(toLength: width, withPad: " ", startingAt: 0), .Magenta)
            + " | "
            + "\(stat.total()) "
            + FormattedText(String(repeating: "+", count: stat.added), .Green)
            + FormattedText(String(repeating: "-", count: stat.removed), .Red)
    )
}

private let commitDateFormat = "E MMM dd HH:mm:ss yyyy Z"
