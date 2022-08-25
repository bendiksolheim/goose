import Foundation
import GitLib
import Tea
import Slowbox

func renderHunk(_ hunk: GitHunk, _ events: [ViewEvent<Message>]) -> [Node] {
    hunk.lines.map { renderDiffLine($0, events) } + [EmptyLine()]
}

func renderDiffLine(_ line: GitHunkLine, _ events: [ViewEvent<Message>]) -> Node {
    var foreground = Color.LightGray
    var background = Color.Default
    switch line.annotation {
    case .Summary:
        foreground = Color.Black
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
