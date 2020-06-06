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
                (.s, .gitCommand(.Stage(.Section(status.untracked.map { $0.file }, .Untracked)))),
                (.tab, .updateVisibility(visibility.merging(["untracked": !open]) { $1 }))
            ]
            let title = TextView<Message>(Text("Untracked files (\(status.untracked.count))", .blue), events: events)
            views.append(CollapseView(content: [title] + status.untracked.map(untrackedMapper), open: open))
            views.append(EmptyLine())
        }

        if status.unstaged.count > 0 {
            let open = model.visibility["unstaged", default: true]
            let events: [ViewEvent<Message>] = [
                (.s, .gitCommand(.Stage(.Section(status.unstaged.map { $0.file }, .Unstaged)))),
                (.tab, .updateVisibility(visibility.merging(["unstaged": !open]) { $1 }))
            ]
            let title = TextView<Message>(Text("Unstaged changes (\(status.unstaged.count))", .blue), events: events)
            let mapper = unstagedMapper(visibility)
            views.append(CollapseView(content: [title] + status.unstaged.flatMap(mapper), open: open))
            views.append(EmptyLine())
        }

        if status.staged.count > 0 {
            let open = model.visibility["staged", default: true]
            let events: [ViewEvent<Message>] = [
                (.u, .gitCommand(.Unstage(.Section(status.staged.map { $0.file }, .Staged)))),
                (.tab, .updateVisibility(visibility.merging(["staged": !open]) { $1 }))
            ]
            let title = TextView<Message>(Text("Staged changes (\(status.staged.count))", .blue), events: events)
            let mapper = stagedMapper(visibility)
            views.append(CollapseView(content: [title] + status.staged.flatMap(mapper), open: open))
            views.append(EmptyLine())
        }

        let open = model.visibility["recent", default: true]
        let events: [ViewEvent<Message>] = [
            (.tab, .updateVisibility(visibility.merging(["recent": !open]) { $1 }))
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
        (.s, .gitCommand(.Stage(.File(untracked.file, .Untracked)))),
        (.u, .gitCommand(.Unstage(.File(untracked.file, .Untracked)))),
        (.x, .info(.Query("Trash \(untracked.file)? (y or n)", .gitCommand(.Remove(untracked.file)))))
    ]
    
    return TextView(untracked.file, events: events)
}

func unstagedMapper(_ visibility: [String : Bool]) -> (Unstaged) -> [TextView<Message>] {
    return { unstaged in
        let open = visibility["unstaged-\(unstaged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .gitCommand(.Stage(.File(unstaged.file, .Unstaged)))),
            (.u, .gitCommand(.Unstage(.File(unstaged.file, .Unstaged)))),
            (.x, .info(.Query("Discard unstaged changes in \(unstaged.file) (y or n)", .gitCommand(.Checkout(unstaged.file))))),
            (.tab, .updateVisibility(visibility.merging(["unstaged-\(unstaged.file)": !open]) { $1 }))
        ]
        
        let hunks = open ? unstaged.diff.flatMap { mapHunks($0, .Unstaged) } : []
    
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

func mapHunks(_ hunk: GitHunk, _ status: Status) -> [TextView<Message>] {
    hunk.lines.map { mapDiffLine($0, hunk.patch, status) }
}

func mapDiffLine(_ line: GitHunkLine, _ patch: String, _ status: Status) -> TextView<Message> {
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
    
    let events: [ViewEvent<Message>] = [
        (.s, .gitCommand(.Stage(.Hunk(patch, status)))),
        (.u, .gitCommand(.Unstage(.Hunk(patch, status))))
    ]
    
    return TextView(Text(line.content, foreground, background), events: events)
}

func stagedMapper(_ visibility: [String : Bool]) -> (Staged) -> [TextView<Message>] {
    return { staged in
        os_log("%{public}@", "\(staged.file)")
    let open = visibility["staged-\(staged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .gitCommand(.Stage(.File(staged.file, .Staged)))),
            (.u, .gitCommand(.Unstage(.File(staged.file, .Staged)))),
            (.tab, .updateVisibility(visibility.merging(["staged-\(staged.file)": !open]) { $1 }))
        ]
        let hunks = open ? staged.diff.flatMap { mapHunks($0, .Staged) } : []
        switch staged.status {
        case .Added:
            return [TextView("new file  \(staged.file)", events: events)] + hunks
        case .Untracked:
            return [TextView(staged.file, events: events)] + hunks
        case .Modified:
            return [TextView("modified  \(staged.file)", events: events)] + hunks
        case .Deleted:
            return [TextView("deleted   \(staged.file)", events: events)] + hunks
        case .Renamed(let target):
            return [TextView("renamed   \(staged.file) -> \(target)", events: events)] + hunks
        case .Copied:
            return [TextView("copied    \(staged.file)", events: events)] + hunks
        }
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
