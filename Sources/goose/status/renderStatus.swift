import Foundation
import GitLib
import tea
import Bow
import os.log

func renderStatus(model: StatusModel) -> [Renderable<Message>] {
    switch model.info {
    case .loading:
        return [TextLine("Loading...")]
    case .error(let error):
        return [TextLine(error.localizedDescription)]
    case .success(let status):
        let visibility = model.visibility
        var sections: [TextLine] = Section(title: headMapper(status.log[0]), items: [], open: true)
        
        if status.untracked.count > 0 {
            let open = model.visibility["untracked", default: true]
            let events: [LineEventHandler<Message>] = [
                (.s, { .stage(.untracked(status.untracked)) }),
                (.tab, { .updateVisibility(visibility.merging(["untracked": !open]) { $1 }) })
            ]
            let title = TextLine<Message>(Text("Untracked files (\(status.untracked.count))", .blue), events: events)
            sections.append(contentsOf: Section(title: title, items: status.untracked.map(untrackedMapper), open: open))
        }

        if status.unstaged.count > 0 {
            let open = model.visibility["unstaged", default: true]
            let events: [LineEventHandler<Message>] = [
                (.s, { .stage(.unstaged(status.unstaged)) }),
                (.tab, { .updateVisibility(visibility.merging(["unstaged": !open]) { $1 })})
            ]
            let title = TextLine<Message>(Text("Unstaged changes (\(status.unstaged.count))", .blue), events: events)
            let mapper = unstagedMapper(visibility)
            sections.append(contentsOf: Section(title: title, items: status.unstaged.flatMap(mapper), open: open))
        }

        if status.staged.count > 0 {
            let open = model.visibility["staged", default: true]
            let events: [LineEventHandler<Message>] = [
                (.u, { .unstage(.staged(status.staged)) }),
                (.tab, { .updateVisibility(visibility.merging(["staged": !open]) { $1 })})
            ]
            let title = TextLine<Message>(Text("Staged changes (\(status.staged.count))", .blue), events: events)
            sections.append(contentsOf: Section(title: title, items: status.staged.map(stagedMapper), open: open))
        }

        let open = model.visibility["recent", default: true]
        let events: [LineEventHandler<Message>] = [
            (.tab, { .updateVisibility(visibility.merging(["recent": !open]) { $1 })})
        ]
        sections.append(contentsOf: Section(title: TextLine("Recent commits", events: events), items: status.log.map(commitMapper), open: open))

        return sections
    }
}

func headMapper(_ commit: GitCommit) -> TextLine<Message> {
    let ref = commit.refName.getOrElse("")
    return TextLine("Head:     " + Text(ref, .cyan) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> TextLine<Message> {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", .cyan) }) + commit.message
    return TextLine(Text(commit.hash.short, .any(241)) + message)
}

func untrackedMapper(_ untracked: Untracked) -> TextLine<Message> {
    let events: [LineEventHandler<Message>] = [
        (.s, { .stage(.untracked([untracked])) }),
        (.u, { .unstage(.untracked([untracked])) })
    ]
    
    return TextLine(untracked.file, events: events)
}

func unstagedMapper(_ visibility: [String : Bool]) -> (Unstaged) -> [TextLine<Message>] {
    return { unstaged in
        let open = visibility["unstaged-\(unstaged.file)", default: false]
        let events: [LineEventHandler<Message>] = [
            (.s, { .stage(.unstaged([unstaged])) }),
            (.u, { .unstage(.unstaged([unstaged])) }),
            (.tab, { .updateVisibility(visibility.merging(["unstaged-\(unstaged.file)": !open]) { $1 }) })
        ]
        
        let hunks = open ? unstaged.diff.flatMap(mapHunks) : []
    
        switch unstaged.status {
        case .Modified:
            return [TextLine("modified  \(unstaged.file)", events: events)] + hunks
        case .Deleted:
            return [TextLine("deleted  \(unstaged.file)", events: events)] + hunks
        case .Added:
            return [TextLine("new file  \(unstaged.file)", events: events)] + hunks
        case .Renamed(let target):
            return [TextLine("renamed   \(unstaged.file) -> \(target)", events: events)] + hunks
        case .Copied:
            return [TextLine("copied    \(unstaged.file)", events: events)] + hunks
        default:
            return [TextLine("Unknown status \(unstaged.status) \(unstaged.file)")]
        }
    }
}

func mapHunks(_ hunk: GitHunk) -> [TextLine<Message>] {
    hunk.lines.map { mapDiffLine($0) }
}

func mapDiffLine(_ line: GitHunkLine) -> TextLine<Message> {
    var foreground = Color.normal
    var background = Color.normal
    switch line.annotation {
    case .Summary:
        background = Color.magenta
    case .Added:
        foreground = Color.green
    case .Removed:
        foreground = Color.red
    case .Context:
        break;
    }
    
    return TextLine(Text(line.content, foreground, background))
}

func stagedMapper(_ staged: Staged) -> TextLine<Message> {
    let events: [LineEventHandler<Message>] = [
        (.s, { .stage(.staged([staged])) }),
        (.u, { .unstage(.staged([staged])) })
    ]
    switch staged.status {
    case .Added:
        return TextLine("new file  \(staged.file)", events: events)
    case .Untracked:
        return TextLine(staged.file, events: events)
    case .Modified:
        return TextLine("modified  \(staged.file)", events: events)
    case .Deleted:
        return TextLine("deleted  \(staged.file)", events: events)
    case .Renamed(let target):
        return TextLine("renamed   \(staged.file) -> \(target)", events: events)
    case .Copied:
        return TextLine("copied    \(staged.file)", events: events)
    }
}
