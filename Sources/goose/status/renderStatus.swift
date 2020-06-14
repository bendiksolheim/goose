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
        var views: [View<Message>] = [headMapper(status.log[0]), EmptyLine()]
        
        if status.untracked.count > 0 {
            views.append(renderUntracked(model, status.untracked))
            views.append(EmptyLine())
        }

        if status.unstaged.count > 0 {
            views.append(renderUnstaged(model, status.unstaged))
            views.append(EmptyLine())
        }

        if status.staged.count > 0 {
            views.append(renderStaged(model, status.staged))
            views.append(EmptyLine())
        }

        views.append(renderLog(model, status.log))

        return views
    }
}

func renderUntracked(_ model: StatusModel, _ untracked: [Untracked]) -> View<Message> {
    let visibility = model.visibility
    let open = model.visibility["untracked", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .gitCommand(.Stage(.Section(untracked.map { $0.file }, .Untracked)))),
        (.x, .info(.Query("Trash \(untracked.count) files? (y or n)", .gitCommand(.Discard(.Section(untracked.map { $0.file }, .Untracked)))))),
        (.tab, .updateVisibility(visibility.merging(["untracked": !open]) { $1 }))
    ]
    let title = TextView<Message>(Text("Untracked files (\(untracked.count))", .blue), events: events)
    return CollapseView(content: [title] + untracked.map(untrackedMapper), open: open)
}

func renderUnstaged(_ model: StatusModel, _ unstaged: [Unstaged]) -> View<Message> {
    let visibility = model.visibility
    let open = model.visibility["unstaged", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .gitCommand(.Stage(.Section(unstaged.map { $0.file }, .Unstaged)))),
        (.x, .info(.Query("Discard unstaged changes in \(unstaged.count) files? (y or n)", .gitCommand(.Discard(.Section(unstaged.map { $0.file }, .Unstaged)))))),
        (.tab, .updateVisibility(visibility.merging(["unstaged": !open]) { $1 }))
    ]
    let title = TextView<Message>(Text("Unstaged changes (\(unstaged.count))", .blue), events: events)
    let mapper = unstagedMapper(visibility)
    return CollapseView(content: [title] + unstaged.flatMap(mapper), open: open)
}

func renderStaged(_ model: StatusModel, _ staged: [Staged]) -> View<Message> {
    let visibility = model.visibility
    let open = model.visibility["staged", default: true]
    let events: [ViewEvent<Message>] = [
        (.u, .gitCommand(.Unstage(.Section(staged.map { $0.file }, .Staged)))),
        (.x, .info(.Query("Discard staged changes in \(staged.count) files? (y or n)", .gitCommand(.Discard(.Section(staged.map { $0.file }, .Staged)))))),
        (.tab, .updateVisibility(visibility.merging(["staged": !open]) { $1 }))
    ]
    let title = TextView<Message>(Text("Staged changes (\(staged.count))", .blue), events: events)
    let mapper = stagedMapper(visibility)
    return CollapseView(content: [title] + staged.flatMap(mapper), open: open)
}

func renderLog(_ model: StatusModel,_ log: [GitCommit]) -> View<Message> {
    let open = model.visibility["recent", default: true]
    let events: [ViewEvent<Message>] = [
        (.tab, .updateVisibility(model.visibility.merging(["recent": !open]) { $1 }))
    ]
    let logTitle = TextView("Recent commits", events: events)
    return CollapseView(content: [logTitle] + log.map(commitMapper), open: open)
}

func headMapper(_ commit: GitCommit) -> TextView<Message> {
    let ref = commit.refName.getOrElse("")
    return TextView("Head:     " + Text(ref, .cyan) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> TextView<Message> {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", .cyan) }) + commit.message
    return TextView(Text(commit.hash.short, .any(241)) + message, events: [(.enter, .getCommit(commit.hash.full))])
}

func untrackedMapper(_ untracked: Untracked) -> TextView<Message> {
    let events: [ViewEvent<Message>] = [
        (.s, .gitCommand(.Stage(.File(untracked.file, .Untracked)))),
        (.u, .gitCommand(.Unstage(.File(untracked.file, .Untracked)))),
        (.x, .info(.Query("Trash \(untracked.file)? (y or n)", .gitCommand(.Discard(.File(untracked.file, .Untracked)))))),
        (.enter, .ViewFile(untracked.file))
    ]
    
    return TextView(untracked.file, events: events)
}

func unstagedMapper(_ visibility: [String : Bool]) -> (Unstaged) -> [TextView<Message>] {
    return { unstaged in
        let open = visibility["unstaged-\(unstaged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .gitCommand(.Stage(.File(unstaged.file, .Unstaged)))),
            (.u, .gitCommand(.Unstage(.File(unstaged.file, .Unstaged)))),
            (.x, .info(.Query("Discard unstaged changes in \(unstaged.file) (y or n)", .gitCommand(.Discard(.File(unstaged.file, .Unstaged)))))),
            (.tab, .updateVisibility(visibility.merging(["unstaged-\(unstaged.file)": !open]) { $1 })),
            (.enter, .ViewFile(unstaged.file))
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
        (.u, .gitCommand(.Unstage(.Hunk(patch, status)))),
        (.x, .info(.Query("Discard hunk? (y or n)", .gitCommand(.Discard(.Hunk(patch, status))))))
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
            (.x, .info(.Query("Discard staged changes in \(staged.file)? (y or n)", .gitCommand(.Discard(.File(staged.file, .Staged)))))),
            (.tab, .updateVisibility(visibility.merging(["staged-\(staged.file)": !open]) { $1 })),
            (.enter, .ViewFile(staged.file))
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

func checkout(files: [String]) -> Message {
    let task = execute(process: ProcessDescription.git(Checkout.head(files: files)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.info(.Message($0.localizedDescription)) }, { _ in Message.commandSuccess })
}

func remove(files: [String]) -> Message {
    let fileManager = FileManager.default
    
    let allExists = files.map { fileManager.fileExists(atPath: $0) }.allSatisfy { $0 }
    
    if allExists {
        do {
            try files.forEach { file in try fileManager.removeItem(atPath: file) }
            return .commandSuccess
        } catch {
            return .info(.Message("File not found"))
        }
    } else {
        return .info(.Message("File not found"))
    }
}
