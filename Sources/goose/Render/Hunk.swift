import Foundation
import GitLib
import tea

func renderHunk(_ hunk: GitHunk, _ events: [ViewEvent<Message>]) -> [TextView<Message>] {
    hunk.lines.map { renderDiffLine($0, events) }
}

func renderDiffLine(_ line: GitHunkLine, _ events: [ViewEvent<Message>]) -> TextView<Message> {
    var foreground = Color.Normal
    var background = Color.Normal
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
    
    return TextView(Text(line.content, foreground, background), events: events)
}
