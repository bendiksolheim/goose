import Foundation
import GitLib
import Tea
import Bow

func renderStatus(status: AsyncData<StatusInfo>) -> [Line<Message>] {
    switch status {
    case .loading:
        return [Line("Loading...")]
    case .error(let error):
        return [Line(error.localizedDescription)]
    case .success(let status):
        var sections: [Line] = Section(title: headMapper(status.log[0]), items: [], open: true)
        
        let untracked = status.changes.filter(isUntracked)
        if untracked.count > 0 {
            let stageAll: [LineEventHandler<Message>] = [(.s, { .stage(untracked) })]
            let title = Line<Message>(Text("Untracked files (\(untracked.count))", [.foreground(.blue)]), stageAll)
            sections.append(contentsOf: Section(title: title, items: untracked.map(changeMapper), open: true))
        }

        let unstaged = status.changes.filter(isUnstaged)
        if unstaged.count > 0 {
            let stageAll: [LineEventHandler<Message>] = [(.s, { .stage(unstaged) })]
            let title = Line<Message>(Text("Unstaged changes (\(unstaged.count))", [.foreground(.blue)]), stageAll)
            sections.append(contentsOf: Section(title: title, items: unstaged.map(changeMapper), open: true))
        }

        let staged = status.changes.filter(isStaged)
        if staged.count > 0 {
            let unstageAll: [LineEventHandler<Message>] = [(.u, { .unstage(staged) })]
            let title = Line<Message>(Text("Staged changes (\(staged.count))", [.foreground(.blue)]), unstageAll)
            sections.append(contentsOf: Section(title: title, items: staged.map(changeMapper), open: true))
        }

        sections.append(contentsOf: Section(title: Line("Recent commits"), items: status.log.map(commitMapper), open: true))

        return sections
    }
}

func fileStatusTitle(_ title: String) -> Line<Message> {
    Line(Text(title, [.foreground(.blue)]))
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
