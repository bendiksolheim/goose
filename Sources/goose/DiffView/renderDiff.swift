import Bow
import Foundation
import GitLib
import Tea
import Slowbox

func renderDiff(diff: DiffModel) -> [Content<Message>] {
    switch diff.commit {
    case .Loading:
        return [Content<Message>("Loading...")]

    case let .Error(error):
        return [Content<Message>("Error: \(error.localizedDescription)")]

    case let .Success(commitInfo):
        let commit = commitInfo.commit
        var views: [Content<Message>] = []
        views.append(Content(Text("Commit \(commit.hash.short)", .White, .Blue)))
        views.append(Content(Text(commit.hash.full, .LightGray)))
        views.append(Content("Author:     \(commit.author) \(commit.email)"))
        views.append(Content("AuthorDate: \(commit.authorDate.format(commitDateFormat))"))
        views.append(Content("Commit:     \(commit.author) \(commit.email)")) // TODO: need to parse committer
        views.append(Content("CommitDate: \(commit.commitDate)"))
        views.append(EmptyLine())
        views.append(Content("Parent      \(commit.parents[0])"))
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

func renderFile(_ file: GitFile) -> [Content<Message>] {
    return [Content("\(file.mode.padding(toLength: 11, withPad: " ", startingAt: 0)) \(file.source)")]
        + file.hunks.flatMap { hunk in renderHunk(hunk, []) }
}

func renderSummary(commit: GitCommit, stats: Stats) -> [Content<Message>] {
    let insertions = stats.stats.map { $0.added }.combineAll()
    let deletions = stats.stats.map { $0.removed }.combineAll()
    var views: [Content<Message>] = [
        Content<Message>(Text(commit.message, .White, .Magenta)),
        EmptyLine(),
        Content<Message>("\(stats.stats.count) files changed, \(insertions) insertions(+), \(deletions) deletions(-)")
    ]
    let maxWidth = stats.stats.map { $0.file.count }.max() ?? 0
    views.append(contentsOf: stats.stats.map { renderStat($0, maxWidth) })
    return views
}

func renderStat(_ stat: Stat, _ width: Int) -> Content<Message> {
    Content(
        Text(stat.file.padding(toLength: width, withPad: " ", startingAt: 0), .Magenta)
            + " | "
            + "\(stat.total()) "
            + Text(String(repeating: "+", count: stat.added), .Green)
            + Text(String(repeating: "-", count: stat.removed), .Red)
    )
}

private let commitDateFormat = "E MMM dd HH:mm:ss yyyy Z"
