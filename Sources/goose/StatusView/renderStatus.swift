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
        var views: [View<Message>] = [headBranchHeader(status.branch, status.log[0])]
        
        if let upstreamBranch = upstreamBranchHeader(status) {
            views.append(upstreamBranch)
        }
        
        views.append(EmptyLine())

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
            views.append(renderLog("Unmerged into \(status.upstream) (\(status.ahead.count))", model, status.ahead))
        }
        
        if !status.log.isEmpty && status.ahead.isEmpty {
            views.append(renderLog("Recent commits", model, status.log))
        }

        return views
    }
}

func upstreamBranchHeader(_ model: StatusInfo) -> View<Message>? {
    let remote = model.config.string("branch.\(model.branch).remote")
    let merge = model.config.string("branch.\(model.branch).merge")
    if (remote == nil && merge == nil) {
        return nil
    } else {
        let isRebase = model.config.bool("branch.\(model.branch).rebase", default: false) || model.config.bool("pull.rebase", default: false)
        let header = isRebase ? "Rebase:   " : "Merge:    "
        let upstreamCommit = model.log.first(where: { $0.refName == Option.some(model.upstream) })?.message
            ?? model.log[0].message
        return TextView(header + Text(model.upstream, .Green) + " " + Text(upstreamCommit))
    }
}

func renderUntracked(_ model: StatusModel, _ untracked: [Untracked]) -> View<Message> {
    let open = model.visibility["untracked", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(untracked.map { $0.file }, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.count) files? (y or n)", .GitCommand(.Discard(.Section(untracked.map { $0.file }, .Untracked)))))),
        (.tab, .UpdateStatus("untracked", model)),
    ]
    let title = TextView<Message>(Text("Untracked files (\(untracked.count))", .Blue), events: events)
    return CollapseView(content: [title] + untracked.map(untrackedMapper), open: open)
}

func renderUnstaged(_ model: StatusModel, _ unstaged: [Unstaged]) -> View<Message> {
    let open = model.visibility["unstaged", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(unstaged.map { $0.file }, .Unstaged)))),
        (.x, .Info(.Query("Discard unstaged changes in \(unstaged.count) files? (y or n)", .GitCommand(.Discard(.Section(unstaged.map { $0.file }, .Unstaged)))))),
        (.tab, .UpdateStatus("unstaged", model)),
    ]
    let title = TextView<Message>(Text("Unstaged changes (\(unstaged.count))", .Blue), events: events)
    let mapper = unstagedMapper(model)
    return CollapseView(content: [title] + unstaged.flatMap(mapper), open: open)
}

func renderStaged(_ model: StatusModel, _ staged: [Staged]) -> View<Message> {
    let open = model.visibility["staged", default: true]
    let events: [ViewEvent<Message>] = [
        (.u, .GitCommand(.Unstage(.Section(staged.map { $0.file }, .Staged)))),
        (.x, .Info(.Query("Discard staged changes in \(staged.count) files? (y or n)", .GitCommand(.Discard(.Section(staged.map { $0.file }, .Staged)))))),
        (.tab, .UpdateStatus("staged", model)),
    ]
    let title = TextView<Message>(Text("Staged changes (\(staged.count))", .Blue), events: events)
    let mapper = stagedMapper(model)
    return CollapseView(content: [title] + staged.flatMap(mapper), open: open)
}

func renderLog(_ title: String, _ model: StatusModel, _ log: [GitCommit]) -> View<Message> {
    let open = model.visibility["recent", default: true]
    let events: [ViewEvent<Message>] = [
        (.tab, .UpdateStatus("recent", model)),
    ]
    let logTitle = TextView(title, events: events)
    return CollapseView(content: [logTitle] + log.map(commitMapper), open: open)
}

func headBranchHeader(_ branch: String, _ commit: GitCommit) -> TextView<Message> {
    return TextView("Head:     " + Text(branch, .Cyan) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> TextView<Message> {
    let message = commit.refName
        .fold(constant(Text(" "))) { name in Text(" \(name) ", .Cyan) } + commit.message
    return TextView(Text(commit.hash.short, .Custom(241)) + message, events: [(.enter, .GitCommand(.GetCommit(commit.hash.full)))])
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

func unstagedMapper(_ model: StatusModel) -> (Unstaged) -> [TextView<Message>] {
    { unstaged in
        let open = model.visibility["unstaged-\(unstaged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .GitCommand(.Stage(.File(unstaged.file, .Unstaged)))),
            (.u, .GitCommand(.Unstage(.File(unstaged.file, .Unstaged)))),
            (.x, .Info(.Query("Discard unstaged changes in \(unstaged.file) (y or n)", .GitCommand(.Discard(.File(unstaged.file, .Unstaged)))))),
            (.tab, .UpdateStatus("unstaged-\(unstaged.file)", model)),
            (.enter, .ViewFile(unstaged.file)),
        ]

        let hunks = open ? unstaged.diff.flatMap { renderHunk($0, makeHunkEvents($0.patch, .Unstaged)) } : []

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

func stagedMapper(_ model: StatusModel) -> (Staged) -> [TextView<Message>] {
    { staged in
        let open = model.visibility["staged-\(staged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .GitCommand(.Stage(.File(staged.file, .Staged)))),
            (.u, .GitCommand(.Unstage(.File(staged.file, .Staged)))),
            (.x, .Info(.Query("Discard staged changes in \(staged.file)? (y or n)", .GitCommand(.Discard(.File(staged.file, .Staged)))))),
            (.tab, .UpdateStatus("staged-\(staged.file)", model)),
            (.enter, .ViewFile(staged.file)),
        ]
        let hunks = open ? staged.diff.flatMap { renderHunk($0, makeHunkEvents($0.patch, .Staged)) } : []
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

func makeHunkEvents(_ patch: String, _ status: Status) -> [ViewEvent<Message>] {
    [
        (.s, .GitCommand(.Stage(.Hunk(patch, status)))),
        (.u, .GitCommand(.Unstage(.Hunk(patch, status)))),
        (.x, .Info(.Query("Discard hunk? (y or n)", .GitCommand(.Discard(.Hunk(patch, status)))))),
    ]
}
