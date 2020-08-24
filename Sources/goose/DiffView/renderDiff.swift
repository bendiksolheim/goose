import Bow
import Foundation
import GitLib
import tea

func renderDiff(diff: DiffModel) -> [View<Message>] {
    switch diff.commit {
    case .Loading:
        return [TextView("Loading...")]

    case let .Error(error):
        return [TextView("Error: \(error.localizedDescription)")]

    case let .Success(commitInfo):
        let commit = commitInfo.commit
        var views: [View<Message>] = []
        views.append(TextView(Text("Commit \(commit.hash.short)", .White, .Blue)))
        views.append(TextView(Text(commit.hash.full, .Custom(240))))
        views.append(TextView("Author:     \(commit.author) \(commit.email)"))
        views.append(TextView("AuthorDate: \(commit.authorDate.format(commitDateFormat))"))
        views.append(TextView("Commit:     \(commit.author) \(commit.email)")) // TODO: need to parse committer
        views.append(TextView("CommitDate: \(commit.commitDate)"))
        views.append(EmptyLine())
        views.append(TextView("Parent      \(commit.parents[0])"))
        views.append(EmptyLine())

        views.append(renderSummary(commit: commit, stats: commitInfo.stats))
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

func renderFile(_ file: GitFile) -> [TextView<Message>] {
    return [TextView("\(file.mode.padding(toLength: 11, withPad: " ", startingAt: 0)) \(file.source)")]
        + file.hunks.flatMap { hunk in renderHunk(hunk, []) }
}

func renderSummary(commit: GitCommit, stats: Stats) -> View<Message> {
    let insertions = stats.stats.map { $0.added }.combineAll()
    let deletions = stats.stats.map { $0.removed }.combineAll()
    var views: [View<Message>] = [
        TextView(Text(commit.message, .White, .Magenta)),
        EmptyLine(),
        TextView("\(stats.stats.count) files changed, \(insertions) insertions(+), \(deletions) deletions(-)")
    ]
    let maxWidth = stats.stats.map { $0.file.count }.max() ?? 0
    views.append(contentsOf: stats.stats.map { renderStat($0, maxWidth) })
    return CollapseView(content: views, open: true)
}

func renderStat(_ stat: Stat, _ width: Int) -> View<Message> {
    TextView(
        Text(stat.file.padding(toLength: width, withPad: " ", startingAt: 0), .Magenta)
            + " | "
            + "\(stat.total()) "
            + Text(String(repeating: "+", count: stat.added), .Green)
            + Text(String(repeating: "-", count: stat.removed), .Red)
    )
}

private let commitDateFormat = "E MMM dd HH:mm:ss yyyy Z"
