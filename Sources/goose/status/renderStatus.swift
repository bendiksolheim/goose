import Foundation
import GitLib
import tea
import Bow
import os.log

func renderStatus(model: StatusModel) -> [View<Message>] {
    switch model.info {
    case .loading:
        return [TextView("Loading...")]
    case .error(let error):
        return [TextView(error.localizedDescription)]
    case .success(let status):
        let visibility = model.visibility
        var views: [View<Message>] = [headMapper(status.log[0]), EmptyLine()]
        //var sections: [TextView] = Section(title: headMapper(status.log[0]), items: [], open: true)
        
        if status.untracked.count > 0 {
            let open = model.visibility["untracked", default: true]
            let events: [ViewEvent<Message>] = [
                (.s, { .stage(.untracked(status.untracked)) }),
                (.tab, { .updateVisibility(visibility.merging(["untracked": !open]) { $1 }) })
            ]
            let title = TextView<Message>(Text("Untracked files (\(status.untracked.count))", .blue), events: events)
            views.append(CollapseView(content: [title] + status.untracked.map(untrackedMapper), open: open))
            views.append(EmptyLine())
            //sections.append(contentsOf: Section(title: title, items: status.untracked.map(untrackedMapper), open: open))
        }

        if status.unstaged.count > 0 {
            let open = model.visibility["unstaged", default: true]
            let events: [ViewEvent<Message>] = [
                (.s, { .stage(.unstaged(status.unstaged)) }),
                (.tab, { .updateVisibility(visibility.merging(["unstaged": !open]) { $1 })})
            ]
            let title = TextView<Message>(Text("Unstaged changes (\(status.unstaged.count))", .blue), events: events)
            let mapper = unstagedMapper(visibility)
            views.append(CollapseView(content: [title] + status.unstaged.flatMap(mapper), open: open))
            views.append(EmptyLine())
            //sections.append(contentsOf: Section(title: title, items: status.unstaged.flatMap(mapper), open: open))
        }

        if status.staged.count > 0 {
            let open = model.visibility["staged", default: true]
            let events: [ViewEvent<Message>] = [
                (.u, { .unstage(.staged(status.staged)) }),
                (.tab, { .updateVisibility(visibility.merging(["staged": !open]) { $1 })})
            ]
            let title = TextView<Message>(Text("Staged changes (\(status.staged.count))", .blue), events: events)
            views.append(CollapseView(content: [title] + status.staged.map(stagedMapper), open: open))
            views.append(EmptyLine())
            //sections.append(contentsOf: Section(title: title, items: status.staged.map(stagedMapper), open: open))
        }

        let open = model.visibility["recent", default: true]
        let events: [ViewEvent<Message>] = [
            (.tab, { .updateVisibility(visibility.merging(["recent": !open]) { $1 })})
        ]
        let logTitle = TextView("Recent commits", events: events)
        views.append(CollapseView(content: [logTitle] + status.log.map(commitMapper), open: open))
        //sections.append(contentsOf: Section(title: TextView("Recent commits", events: events), items: status.log.map(commitMapper), open: open))

        return views
    }
}

func headMapper(_ commit: GitCommit) -> TextView<Message> {
    let ref = commit.refName.getOrElse("")
    return TextView("Head:     " + Text(ref, .cyan) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> TextView<Message> {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", .cyan) }) + commit.message
    return TextView(Text(commit.hash.short, .any(241)) + message)
}

func untrackedMapper(_ untracked: Untracked) -> TextView<Message> {
    let events: [ViewEvent<Message>] = [
        (.s, { .stage(.untracked([untracked])) }),
        (.u, { .unstage(.untracked([untracked])) })
    ]
    
    return TextView(untracked.file, events: events)
}

func unstagedMapper(_ visibility: [String : Bool]) -> (Unstaged) -> [TextView<Message>] {
    return { unstaged in
        let open = visibility["unstaged-\(unstaged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, { .stage(.unstaged([unstaged])) }),
            (.u, { .unstage(.unstaged([unstaged])) }),
            (.x, { .info(.Query("Discard unstaged changes in \(unstaged.file) (y or n)", task({ checkout(file: unstaged.file) }) )) }),
            (.tab, { .updateVisibility(visibility.merging(["unstaged-\(unstaged.file)": !open]) { $1 }) })
        ]
        
        let hunks = open ? unstaged.diff.flatMap(mapHunks) : []
    
        switch unstaged.status {
        case .Modified:
            return [TextView("modified  \(unstaged.file)", events: events)] + hunks
        case .Deleted:
            return [TextView("deleted   \(unstaged.file)", events: events)] + hunks
        case .Added:
            return [TextView("new file  \(unstaged.file)", events: events)] + hunks
        case .Renamed(let target):
            return [TextView("renamed   \(unstaged.file) -> \(target)", events: events)] + hunks
        case .Copied:
            return [TextView("copied    \(unstaged.file)", events: events)] + hunks
        default:
            return [TextView("Unknown status \(unstaged.status) \(unstaged.file)")]
        }
    }
}

func mapHunks(_ hunk: GitHunk) -> [TextView<Message>] {
    hunk.lines.map { mapDiffLine($0, hunk.patch) }
}

func mapDiffLine(_ line: GitHunkLine, _ patch: String) -> TextView<Message> {
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
    
    return TextView(Text(line.content, foreground, background), events: [(.s, { .stagePatch(patch) })])
}

func stagedMapper(_ staged: Staged) -> TextView<Message> {
    let events: [ViewEvent<Message>] = [
        (.s, { .stage(.staged([staged])) }),
        (.u, { .unstage(.staged([staged])) })
    ]
    switch staged.status {
    case .Added:
        return TextView("new file  \(staged.file)", events: events)
    case .Untracked:
        return TextView(staged.file, events: events)
    case .Modified:
        return TextView("modified  \(staged.file)", events: events)
    case .Deleted:
        return TextView("deleted   \(staged.file)", events: events)
    case .Renamed(let target):
        return TextView("renamed   \(staged.file) -> \(target)", events: events)
    case .Copied:
        return TextView("copied    \(staged.file)", events: events)
    }
}

func checkout(file: String) -> Message {
    let task = execute(process: ProcessDescription.git(Checkout.head(file: file)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info(.Info($0.localizedDescription)) }, { _ in Message.commandSuccess })
}

func remove(file: String) -> Message {
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: file) {
        do {
            try fileManager.removeItem(atPath: file)
            return .info(.None)
        } catch {
            return .info(.Info("File not found: \(file)"))
        }
    } else {
        return .info(.Info("File not found: \(file)"))
    }
}
