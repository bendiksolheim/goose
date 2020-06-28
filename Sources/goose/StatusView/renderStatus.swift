import Bow
import Foundation
import GitLib
import tea

func renderStatus(model: StatusModel) -> [View<Message>] {
    switch model.info {
    case .Loading:
        return [TextView("Loading...")]

    case let .Error(error):
        return [TextView(error.localizedDescription)]

    case let .Success(status):
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

        if !status.ahead.isEmpty {
            views.append(renderLog("Unmerged into \(status.tracking) (\(status.ahead.count))", model, status.ahead))
        }
        
        if !status.log.isEmpty && status.ahead.isEmpty {
            views.append(renderLog("Recent commits", model, status.log))
        }

        return views
    }
}

func renderUntracked(_ model: StatusModel, _ untracked: [Untracked]) -> View<Message> {
    let visibility = model.visibility
    let open = model.visibility["untracked", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(untracked.map { $0.file }, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.count) files? (y or n)", .GitCommand(.Discard(.Section(untracked.map { $0.file }, .Untracked)))))),
        (.tab, .UpdateVisibility(visibility.merging(["untracked": !open]) { $1 })),
    ]
    let title = TextView<Message>(Text("Untracked files (\(untracked.count))", .Blue), events: events)
    return CollapseView(content: [title] + untracked.map(untrackedMapper), open: open)
}

func renderUnstaged(_ model: StatusModel, _ unstaged: [Unstaged]) -> View<Message> {
    let visibility = model.visibility
    let open = model.visibility["unstaged", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(unstaged.map { $0.file }, .Unstaged)))),
        (.x, .Info(.Query("Discard unstaged changes in \(unstaged.count) files? (y or n)", .GitCommand(.Discard(.Section(unstaged.map { $0.file }, .Unstaged)))))),
        (.tab, .UpdateVisibility(visibility.merging(["unstaged": !open]) { $1 })),
    ]
    let title = TextView<Message>(Text("Unstaged changes (\(unstaged.count))", .Blue), events: events)
    let mapper = unstagedMapper(visibility)
    return CollapseView(content: [title] + unstaged.flatMap(mapper), open: open)
}

func renderStaged(_ model: StatusModel, _ staged: [Staged]) -> View<Message> {
    let visibility = model.visibility
    let open = model.visibility["staged", default: true]
    let events: [ViewEvent<Message>] = [
        (.u, .GitCommand(.Unstage(.Section(staged.map { $0.file }, .Staged)))),
        (.x, .Info(.Query("Discard staged changes in \(staged.count) files? (y or n)", .GitCommand(.Discard(.Section(staged.map { $0.file }, .Staged)))))),
        (.tab, .UpdateVisibility(visibility.merging(["staged": !open]) { $1 })),
    ]
    let title = TextView<Message>(Text("Staged changes (\(staged.count))", .Blue), events: events)
    let mapper = stagedMapper(visibility)
    return CollapseView(content: [title] + staged.flatMap(mapper), open: open)
}

func renderLog(_ title: String, _ model: StatusModel, _ log: [GitCommit]) -> View<Message> {
    let open = model.visibility["recent", default: true]
    let events: [ViewEvent<Message>] = [
        (.tab, .UpdateVisibility(model.visibility.merging(["recent": !open]) { $1 })),
    ]
    let logTitle = TextView(title, events: events)
    return CollapseView(content: [logTitle] + log.map(commitMapper), open: open)
}

func headMapper(_ commit: GitCommit) -> TextView<Message> {
    let ref = commit.refName.getOrElse("")
    return TextView("Head:     " + Text(ref, .Cyan) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> TextView<Message> {
    let message = commit.refName
        .fold(constant(Text(" "))) { name in Text(" \(name) ", .Cyan) } + commit.message
    return TextView(Text(commit.hash.short, .Custom(241)) + message, events: [(.enter, .GetCommit(commit.hash.full))])
}

func untrackedMapper(_ untracked: Untracked) -> TextView<Message> {
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.File(untracked.file, .Untracked)))),
        (.u, .GitCommand(.Unstage(.File(untracked.file, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.file)? (y or n)", .GitCommand(.Discard(.File(untracked.file, .Untracked)))))),
        (.enter, .ViewFile(untracked.file)),
    ]

    return TextView(untracked.file, events: events)
}

func unstagedMapper(_ visibility: [String: Bool]) -> (Unstaged) -> [TextView<Message>] {
    { unstaged in
        let open = visibility["unstaged-\(unstaged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .GitCommand(.Stage(.File(unstaged.file, .Unstaged)))),
            (.u, .GitCommand(.Unstage(.File(unstaged.file, .Unstaged)))),
            (.x, .Info(.Query("Discard unstaged changes in \(unstaged.file) (y or n)", .GitCommand(.Discard(.File(unstaged.file, .Unstaged)))))),
            (.tab, .UpdateVisibility(visibility.merging(["unstaged-\(unstaged.file)": !open]) { $1 })),
            (.enter, .ViewFile(unstaged.file)),
        ]

        let hunks = open ? unstaged.diff.flatMap { mapHunks($0, .Unstaged) } : []

        switch unstaged.status {
        case .Modified:
            return [TextView("modified  \(unstaged.file)", events: events)] + hunks

        case .Deleted:
            return [TextView("deleted   \(unstaged.file)", events: events)] + hunks

        case .Added:
            return [TextView("new file  \(unstaged.file)", events: events)] + hunks

        case let .Renamed(target):
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

    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Hunk(patch, status)))),
        (.u, .GitCommand(.Unstage(.Hunk(patch, status)))),
        (.x, .Info(.Query("Discard hunk? (y or n)", .GitCommand(.Discard(.Hunk(patch, status)))))),
    ]

    return TextView(Text(line.content, foreground, background), events: events)
}

func stagedMapper(_ visibility: [String: Bool]) -> (Staged) -> [TextView<Message>] {
    { staged in
        log(staged.file)
        let open = visibility["staged-\(staged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .GitCommand(.Stage(.File(staged.file, .Staged)))),
            (.u, .GitCommand(.Unstage(.File(staged.file, .Staged)))),
            (.x, .Info(.Query("Discard staged changes in \(staged.file)? (y or n)", .GitCommand(.Discard(.File(staged.file, .Staged)))))),
            (.tab, .UpdateVisibility(visibility.merging(["staged-\(staged.file)": !open]) { $1 })),
            (.enter, .ViewFile(staged.file)),
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

        case let .Renamed(target):
            return [TextView("renamed   \(staged.file) -> \(target)", events: events)] + hunks

        case .Copied:
            return [TextView("copied    \(staged.file)", events: events)] + hunks
        }
    }
}
