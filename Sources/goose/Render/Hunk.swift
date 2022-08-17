import Foundation
import GitLib
import Tea
import Slowbox

func renderHunk(_ hunk: GitHunk, _ events: [ViewEvent<Message>]) -> [Node] {
    hunk.lines.map { renderDiffLine($0, events) }
}

func renderDiffLine(_ line: GitHunkLine, _ events: [ViewEvent<Message>]) -> Node {
    var foreground = Color.Default
    var background = Color.Default
    switch line.annotation {
    case .Summary:
        background = Color.Magenta

    case .Added:
        foreground = Color.Green

    case .Removed:
        foreground = Color.Red

    case .Context:
        break
    }

    return Text(FormattedText(line.content, foreground, background), events)
}
