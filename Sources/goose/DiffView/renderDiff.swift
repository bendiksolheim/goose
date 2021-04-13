import Bow
import Foundation
import GitLib
import tea
import TermSwift

func renderDiff(diff: DiffModel) -> [Line<Message>] {
    switch diff.commit {
    case .Loading:
        return [Line("Loading...")]

    case let .Error(error):
        return [Line("Error: \(error.localizedDescription)")]

    case let .Success(commitInfo):
        let commit = commitInfo.commit
        var views: [Line<Message>] = []
        views.append(Line(Text("Commit \(commit.hash.short)", .White, .Blue)))
        views.append(Line(Text(commit.hash.full, .LightGray)))
        views.append(Line("Author:     \(commit.author) \(commit.email)"))
        views.append(Line("AuthorDate: \(commit.authorDate.format(commitDateFormat))"))
        views.append(Line("Commit:     \(commit.author) \(commit.email)")) // TODO: need to parse committer
        views.append(Line("CommitDate: \(commit.commitDate)"))
        views.append(EmptyLine())
        views.append(Line("Parent      \(commit.parents[0])"))
        views.append(EmptyLine())

        views.append(contentsOf: renderSummary(commit: commit, stats: commitInfo.stats))
        views.append(EmptyLine())

        views.append(contentsOf:
            commit.diff.map { diff in
                diff.files.flatMap(renderFile)
            }
            .combineAll()
        )

        return views
    }
}

func renderFile(_ file: GitFile) -> [Line<Message>] {
    return [Line("\(file.mode.padding(toLength: 11, withPad: " ", startingAt: 0)) \(file.source)")]
        + file.hunks.flatMap { hunk in renderHunk(hunk, []) }
}

func renderSummary(commit: GitCommit, stats: Stats) -> [Line<Message>] {
    let insertions = stats.stats.map { $0.added }.combineAll()
    let deletions = stats.stats.map { $0.removed }.combineAll()
    var views: [Line<Message>] = [
        Line(Text(commit.message, .White, .Magenta)),
        EmptyLine(),
        Line("\(stats.stats.count) files changed, \(insertions) insertions(+), \(deletions) deletions(-)")
    ]
    let maxWidth = stats.stats.map { $0.file.count }.max() ?? 0
    views.append(contentsOf: stats.stats.map { renderStat($0, maxWidth) })
    return views
}

func renderStat(_ stat: Stat, _ width: Int) -> Line<Message> {
    Line(
        Text(stat.file.padding(toLength: width, withPad: " ", startingAt: 0), .Magenta)
            + " | "
            + "\(stat.total()) "
            + Text(String(repeating: "+", count: stat.added), .Green)
            + Text(String(repeating: "-", count: stat.removed), .Red)
    )
}

private let commitDateFormat = "E MMM dd HH:mm:ss yyyy Z"
