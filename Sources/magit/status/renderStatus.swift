import Foundation
import GitLib
import Tea
import Bow

func renderStatus(status: AsyncData<StatusModel>) -> [Line<Message>] {
    switch status {
    case .loading:
        return [Line("Loading...")]
    case .error(let error):
        return [Line(error.localizedDescription)]
    case .success(let status):
        var sections: [Line] = Section(title: headMapper(status.log[0]), items: [], open: true)
        
        if status.untracked.count > 0 {
            let stageAll: [LineEventHandler<Message>] = [(.s, { .stage(status.untracked) })]
            let title = Line<Message>(Text("Untracked files (\(status.untracked.count))", [.foreground(.blue)]), stageAll)
            sections.append(contentsOf: Section(title: title, items: status.untracked.map(changeMapper), open: true))
        }

        if status.unstaged.count > 0 {
            let stageAll: [LineEventHandler<Message>] = [(.s, { .stage(status.unstaged) })]
            let title = Line<Message>(Text("Unstaged changes (\(status.unstaged.count))", [.foreground(.blue)]), stageAll)
            sections.append(contentsOf: Section(title: title, items: status.unstaged.map(changeMapper), open: true))
        }

        if status.staged.count > 0 {
            let unstageAll: [LineEventHandler<Message>] = [(.u, { .unstage(status.staged) })]
            let title = Line<Message>(Text("Staged changes (\(status.staged.count))", [.foreground(.blue)]), unstageAll)
            sections.append(contentsOf: Section(title: title, items: status.staged.map(changeMapper), open: true))
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
