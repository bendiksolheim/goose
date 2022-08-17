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
    let author = Text(FormattedText(commit.author, .LightRed) + "   " + FormattedText("8 years"))
    return Horizontal(.Fill, .Auto) {
        hash
        message
        author
    }
}
