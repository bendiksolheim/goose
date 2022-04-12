import Bow
import Foundation
import GitLib
import Tea
import os.log

func renderStatus(model: StatusModel) -> [Content<Message>] {
    switch model.info {
    case .Loading:
        return [Content("Loading...")]

    case let .Error(error):
        return [Content(error.localizedDescription)]

    case let .Success(status):
        var views: [Content<Message>] = [headBranchHeader(status.branch, status.log[0])]
        
        if let upstreamBranch = upstreamBranchHeader(status) {
            views.append(upstreamBranch)
        }
        
        views.append(EmptyLine())

        if status.untracked.count > 0 {
            views.append(contentsOf: renderUntracked(model, status.untracked))
            views.append(EmptyLine())
        }

        if status.unstaged.count > 0 {
            views.append(contentsOf: renderUnstaged(model, status.unstaged))
            views.append(EmptyLine())
        }

        if status.staged.count > 0 {
            views.append(contentsOf: renderStaged(model, status.staged))
            views.append(EmptyLine())
        }

        if !status.ahead.isEmpty {
            views.append(contentsOf: renderLog("Unmerged into \(status.upstream) (\(status.ahead.count))", model, status.ahead))
        }
        
        if !status.log.isEmpty && status.ahead.isEmpty {
            views.append(contentsOf: renderLog("Recent commits", model, status.log))
        }

        return views
    }
}

func upstreamBranchHeader(_ model: StatusInfo) -> Content<Message>? {
    let remote = model.config.string("branch.\(model.branch).remote")
    let merge = model.config.string("branch.\(model.branch).merge")
    if (remote == nil && merge == nil) {
        return nil
    } else {
        let isRebase = model.config.bool("branch.\(model.branch).rebase", default: false) || model.config.bool("pull.rebase", default: false)
        let header = isRebase ? "Rebase:   " : "Merge:    "
        let upstreamCommit = model.log.first(where: { $0.refName == Option.some(model.upstream) })?.message
            ?? model.log[0].message
        return Content(header + Text(model.upstream, .Green) + " " + Text(upstreamCommit))
    }
}

func renderUntracked(_ model: StatusModel, _ untracked: [Untracked]) -> [Content<Message>] {
    let open = model.visibility["untracked", default: true]
    os_log("Open: %{public}@", "\(open)")
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(untracked.map { $0.file }, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.count) files? (y or n)", .GitCommand(.Discard(.Section(untracked.map { $0.file }, .Untracked)))))),
        (.tab, .UpdateStatus("untracked", model)),
    ]
    let title = Content<Message>(Text("Untracked files (\(untracked.count))", .Blue), events: events)
    if open {
        return [title] + untracked.map(untrackedMapper)
    } else {
        return [title]
    }
}

func renderUnstaged(_ model: StatusModel, _ unstaged: [Unstaged]) -> [Content<Message>] {
    let open = model.visibility["unstaged", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(unstaged.map { $0.file }, .Unstaged)))),
        (.x, .Info(.Query("Discard unstaged changes in \(unstaged.count) files? (y or n)", .GitCommand(.Discard(.Section(unstaged.map { $0.file }, .Unstaged)))))),
        (.tab, .UpdateStatus("unstaged", model)),
    ]
    let title = Content<Message>(Text("Unstaged changes (\(unstaged.count))", .Blue), events: events)
    let mapper = unstagedMapper(model)
    if open {
        return [title] + unstaged.flatMap(mapper)
    } else {
        return [title]
    }
}

func renderStaged(_ model: StatusModel, _ staged: [Staged]) -> [Content<Message>] {
    let open = model.visibility["staged", default: true]
    let events: [ViewEvent<Message>] = [
        (.u, .GitCommand(.Unstage(.Section(staged.map { $0.file }, .Staged)))),
        (.x, .Info(.Query("Discard staged changes in \(staged.count) files? (y or n)", .GitCommand(.Discard(.Section(staged.map { $0.file }, .Staged)))))),
        (.tab, .UpdateStatus("staged", model)),
    ]
    let title = Content<Message>(Text("Staged changes (\(staged.count))", .Blue), events: events)
    let mapper = stagedMapper(model)
    if open {
        return [title] + staged.flatMap(mapper)
    } else {
        return [title]
    }
}

func renderLog(_ title: String, _ model: StatusModel, _ log: [GitCommit]) -> [Content<Message>] {
    let open = model.visibility["recent", default: true]
    let events: [ViewEvent<Message>] = [
        (.tab, .UpdateStatus("recent", model)),
    ]
    let logTitle = Content(Text(title, .Blue), events: events)
    if open {
        return [logTitle] + log.map(commitMapper)
    } else {
        return [logTitle]
    }
}

func headBranchHeader(_ branch: String, _ commit: GitCommit) -> Content<Message> {
    return Content<Message>("Head:     " + Text(branch, .Cyan) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> Content<Message> {
    let message = commit.refName
        .fold(constant(Text(" "))) { name in Text(" \(name) ", .Cyan) } + commit.message
    return Content<Message>(Text(commit.hash.short, .LightGray) + message, events: [(.enter, .GitCommand(.GetCommit(commit.hash.full)))])
}

func untrackedMapper(_ untracked: Untracked) -> Content<Message> {
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.File(untracked.file, .Untracked)))),
        (.u, .GitCommand(.Unstage(.File(untracked.file, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.file)? (y or n)", .GitCommand(.Discard(.File(untracked.file, .Untracked)))))),
        (.enter, .ViewFile(untracked.file)),
    ]

    return Content(untracked.file, events: events)
}

func unstagedMapper(_ model: StatusModel) -> (Unstaged) -> [Content<Message>] {
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
            return [Content("modified  \(unstaged.file)", events: events)] + hunks

        case .Deleted:
            return [Content("deleted   \(unstaged.file)", events: events)] + hunks

        case .Added:
            return [Content("new file  \(unstaged.file)", events: events)] + hunks

        case let .Renamed(target):
            return [Content("renamed   \(unstaged.file) -> \(target)", events: events)] + hunks

        case .Copied:
            return [Content("copied    \(unstaged.file)", events: events)] + hunks

        default:
            return [Content("Unknown status \(unstaged.status) \(unstaged.file)")]
        }
    }
}

func stagedMapper(_ model: StatusModel) -> (Staged) -> [Content<Message>] {
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
            return [Content("new file  \(staged.file)", events: events)] + hunks

        case .Untracked:
            return [Content(staged.file, events: events)] + hunks

        case .Modified:
            return [Content("modified  \(staged.file)", events: events)] + hunks

        case .Deleted:
            return [Content("deleted   \(staged.file)", events: events)] + hunks

        case let .Renamed(target):
            return [Content("renamed   \(staged.file) -> \(target)", events: events)] + hunks

        case .Copied:
            return [Content("copied    \(staged.file)", events: events)] + hunks
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
