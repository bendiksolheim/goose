import Foundation
import GitLib
import Tea
import Bow

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
                (.s, { .stage(status.untracked) }),
                (.tab, { .updateVisibility(visibility.merging(["untracked": !open]) { $1 }) })
            ]
            let title = Line<Message>(Text("Untracked files (\(status.untracked.count))", [.foreground(.blue)]), events)
            sections.append(contentsOf: Section(title: title, items: status.untracked.map(changeMapper), open: open))
        }

        if status.unstaged.count > 0 {
            let open = model.visibility["unstaged", default: true]
            let events: [LineEventHandler<Message>] = [
                (.s, { .stage(status.unstaged) }),
                (.tab, { .updateVisibility(visibility.merging(["unstaged": !open]) { $1 })})
            ]
            let title = Line<Message>(Text("Unstaged changes (\(status.unstaged.count))", [.foreground(.blue)]), events)
            sections.append(contentsOf: Section(title: title, items: status.unstaged.map(changeMapper), open: open))
        }

        if status.staged.count > 0 {
            let open = model.visibility["staged", default: true]
            let events: [LineEventHandler<Message>] = [
                (.u, { .unstage(status.staged) }),
                (.tab, { .updateVisibility(visibility.merging(["staged": !open]) { $1 })})
            ]
            let title = Line<Message>(Text("Staged changes (\(status.staged.count))", [.foreground(.blue)]), events)
            sections.append(contentsOf: Section(title: title, items: status.staged.map(changeMapper), open: open))
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

func changeMapper(_ change: GitChange) -> Line<Message> {
    let events: [LineEventHandler<Message>] = [
        (.s, { .stage([change]) }),
        (.u, { .unstage([change]) })
    ]
    switch change.status {
    case .Added:
        return Line("new file  \(change.file)", events)
    case .Untracked:
        return Line(change.file, events)
    case .Modified:
        return Line("modified  \(change.file)", events)
    case .Deleted:
        return Line("deleted  \(change.file)", events)
    case .Renamed:
        return Line("renamed   \(change.file)", events)
    case .Copied:
        return Line("copied    \(change.file)", events)
    }
}
