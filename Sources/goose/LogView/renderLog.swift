import Bow
import Foundation
import Tea
import GitLib

func renderLog(log: AsyncData<LogInfo>) -> Node {
    switch log {
    case .Loading:
        return Text("Loading...")

    case let .Error(error):
        return Text("Error: \(error.localizedDescription)")

    case let .Success(log):
        let title = Text("Commits in \(log.branch)")
        let commits = log.commits.map(renderCommit)
        return Vertical(.Fill, .Fill) {
            title
            Vertical(.Fill, .Auto) {
                commits
            }
        }
    }
}

func renderCommit(_ commit: GitCommit) -> Node {
    let hash = Text(FormattedText(commit.hash.short, .DarkGray), [(.enter, Message.GitCommand(.GetCommit(commit.hash.full)))])
    let messageText: TextType = commit.refName.fold(
            { commit.message },
            { ref in " " + FormattedText("\(ref)", .Cyan) + " " + commit.message }
    )
    let message = Text(messageText, [(.enter, Message.GitCommand(.GetCommit(commit.hash.full)))], .Fill)
    let author = Text(FormattedText(commit.author, .LightRed) + "   " + formatCommitDate(commit.commitDate))
    return Horizontal(.Fill, .Auto) {
        hash
        message
        author
    }
}

// Taken from https://github.com/magit/magit/blob/bf0ef3826bcda9d90f3e3c9a8f801c2c3c01bc5b/lisp/magit-margin.el#L204
let seconds: [(String, String, Double)] = [
    ("year", "years", (60 * 60 * 24 * 365.2425).rounded()),
    ("month", "months", (60 * 60 * 24 * 30.436875).rounded()),
    ("week", "weeks", (60 * 60 * 24 * 7)),
    ("day", "days", (60 * 60 * 24)),
    ("hour", "hours", (60 * 60)),
    ("minute", "minutes", 60),
    ("second", "seconds", 1)
]

func formatCommitDate(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    let (unit, units, seconds) = seconds.first { (unit, units, seconds) in
        interval > seconds
    }!

    let value = Int((interval / seconds).rounded())
    return "\(value) \(value > 1 ? units : unit)"
}