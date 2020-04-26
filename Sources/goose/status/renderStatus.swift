import Foundation
import GitLib
import Tea
import Bow
import os.log

func renderStatus(model: StatusModel) -> [Line<Message>] {
    switch model.info {
    case .loading:
        return [Line("Loading...")]
    case .error(let error):
        return [Line(error.localizedDescription)]
    case .success(let status):
        let visibility = model.visibility
        var sections: [Line] = Section(title: headMapper(status.log[0]), items: [], open: true)
        
        if status.untracked.count > 0 {
            let open = model.visibility["untracked", default: true]
            let events: [LineEventHandler<Message>] = [
                (.s, { .stage(.untracked(status.untracked)) }),
                (.tab, { .updateVisibility(visibility.merging(["untracked": !open]) { $1 }) })
            ]
            let title = Line<Message>(Text("Untracked files (\(status.untracked.count))", [.foreground(.blue)]), events)
            sections.append(contentsOf: Section(title: title, items: status.untracked.map(untrackedMapper), open: open))
        }

        if status.unstaged.count > 0 {
            let open = model.visibility["unstaged", default: true]
            let events: [LineEventHandler<Message>] = [
                (.s, { .stage(.unstaged(status.unstaged)) }),
                (.tab, { .updateVisibility(visibility.merging(["unstaged": !open]) { $1 })})
            ]
            let title = Line<Message>(Text("Unstaged changes (\(status.unstaged.count))", [.foreground(.blue)]), events)
            sections.append(contentsOf: Section(title: title, items: status.unstaged.map(unstagedMapper), open: open))
        }

        if status.staged.count > 0 {
            let open = model.visibility["staged", default: true]
            let events: [LineEventHandler<Message>] = [
                (.u, { .unstage(.staged(status.staged)) }),
                (.tab, { .updateVisibility(visibility.merging(["staged": !open]) { $1 })})
            ]
            let title = Line<Message>(Text("Staged changes (\(status.staged.count))", [.foreground(.blue)]), events)
            sections.append(contentsOf: Section(title: title, items: status.staged.map(stagedMapper), open: open))
        }

        let open = model.visibility["recent", default: true]
        let events: [LineEventHandler<Message>] = [
            (.tab, { .updateVisibility(visibility.merging(["recent": !open]) { $1 })})
        ]
        sections.append(contentsOf: Section(title: Line("Recent commits", events), items: status.log.map(commitMapper), open: open))

        return sections
    }
}

func headMapper(_ commit: GitCommit) -> Line<Message> {
    let ref = commit.refName.getOrElse("")
    return Line("Head:     " + Text(ref, [.foreground(.cyan)]) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> Line<Message> {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", [.foreground(.cyan)]) }) + commit.message
    return Line(Text(commit.hash.short, [.foreground(.any(241))]) + message)
}

func untrackedMapper(_ untracked: Untracked) -> Line<Message> {
    let events: [LineEventHandler<Message>] = [
        (.s, { .stage(.untracked([untracked])) }),
        (.u, { .unstage(.untracked([untracked])) })
    ]
    
    return Line(untracked.file, events)
}

func unstagedMapper(_ unstaged: Unstaged) -> Line<Message> {
    let events: [LineEventHandler<Message>] = [
        (.s, { .stage(.unstaged([unstaged])) }),
        (.u, { .unstage(.unstaged([unstaged])) })
    ]
    
    switch unstaged.status {
    case .Modified:
    return Line("modified  \(unstaged.file)", events)
    case .Deleted:
    return Line("deleted  \(unstaged.file)", events)
    case .Added:
        return Line("new file  \(unstaged.file)", events)
    case .Renamed:
        return Line("renamed   \(unstaged.file)", events)
    case .Copied:
        return Line("copied    \(unstaged.file)", events)
    default:
        return Line("Unknown status \(unstaged.status) \(unstaged.file)")
    }
}

func stagedMapper(_ staged: Staged) -> Line<Message> {
    let events: [LineEventHandler<Message>] = [
        (.s, { .stage(.staged([staged])) }),
        (.u, { .unstage(.staged([staged])) })
    ]
    switch staged.status {
    case .Added:
        return Line("new file  \(staged.file)", events)
    case .Untracked:
        return Line(staged.file, events)
    case .Modified:
        return Line("modified  \(staged.file)", events)
    case .Deleted:
        return Line("deleted  \(staged.file)", events)
    case .Renamed:
        return Line("renamed   \(staged.file)", events)
    case .Copied:
        return Line("copied    \(staged.file)", events)
    }
}
