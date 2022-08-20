import Bow
import Foundation
import GitLib
import Tea
import Slowbox

func renderStatus(model: StatusModel) -> Node {
    switch model.info {
    case .Loading:
        return Text("Loading...")

    case let .Error(error):
        return Text(error.localizedDescription)

    case let .Success(status):
        let view = Vertical(.Auto, .Auto) {
            [Text("Head:     " + FormattedText(status.branch, .Cyan) + " " + status.log[0].message)]

            if let upstreamBranch = upstreamBranchHeader(status) {
                upstreamBranch
            }

            [EmptyLine()]

            if status.untracked.count > 0 {
                renderUntracked(model, status.untracked)
            }

            if status.unstaged.count > 0 {
                renderUnstaged(model, status.unstaged)
            }

            if status.staged.count > 0 {
                renderStaged(model, status.staged)
            }

            if status.stash.count > 0 {
                renderStash(model, status.stash)
            }

            if !status.ahead.isEmpty {
                renderLog("Unmerged into \(status.upstream) (\(status.ahead.count))", model, status.ahead)
            }

            if !status.log.isEmpty && status.ahead.isEmpty {
                renderLog("Recent commits", model, status.log)
            }
        }

        return view
    }
}

func upstreamBranchHeader(_ model: StatusInfo) -> [ Node ]? {
    let remote = model.config.string("branch.\(model.branch).remote")
    let merge = model.config.string("branch.\(model.branch).merge")
    if (remote == nil && merge == nil) {
        return nil
    } else {
        let isRebase = model.config.bool("branch.\(model.branch).rebase", default: false) || model.config.bool("pull.rebase", default: false)
        let header = isRebase ? "Rebase:   " : "Merge:    "
        let upstreamCommit = model.log.first(where: { $0.refName == Option.some(model.upstream) })?.message
            ?? model.log[0].message
        return [Text(header + FormattedText(model.upstream, .Green) + " " + FormattedText(upstreamCommit))]
    }
}

func renderUntracked(_ model: StatusModel, _ untracked: [Untracked]) -> [Node] {
    let open = model.visibility["untracked", default: true]
    Tea.debug("Open: \(open)")
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(untracked.map { $0.file }, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.count) files? (y or n)", .GitCommand(.Discard(.Section(untracked.map { $0.file }, .Untracked)))))),
        (.tab, .UpdateStatus("untracked", model)),
    ]
    let content = untracked.map(untrackedMapper)
    return collapsible(FormattedText("Untracked files (\(untracked.count))", .Blue), events, open, content) + [EmptyLine()]
}

func renderUnstaged(_ model: StatusModel, _ unstaged: [Unstaged]) -> [Node] {
    let open = model.visibility["unstaged", default: true]
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.Section(unstaged.map { $0.file }, .Unstaged)))),
        (.x, .Info(.Query("Discard unstaged changes in \(unstaged.count) files? (y or n)", .GitCommand(.Discard(.Section(unstaged.map { $0.file }, .Unstaged)))))),
        (.tab, .UpdateStatus("unstaged", model)),
    ]
    let mapper = unstagedMapper(model)
    let content = unstaged.flatMap(mapper)
    return collapsible(FormattedText("Unstaged changes (\(unstaged.count))", .Blue), events, open, content) + [EmptyLine()]
}

func renderStaged(_ model: StatusModel, _ staged: [Staged]) -> [Node] {
    let open = model.visibility["staged", default: true]
    let events: [ViewEvent<Message>] = [
        (.u, .GitCommand(.Unstage(.Section(staged.map { $0.file }, .Staged)))),
        (.x, .Info(.Query("Discard staged changes in \(staged.count) files? (y or n)", .GitCommand(.Discard(.Section(staged.map { $0.file }, .Staged)))))),
        (.tab, .UpdateStatus("staged", model)),
    ]
    let mapper = stagedMapper(model)
    let content = staged.flatMap(mapper)
    return collapsible(FormattedText("Staged changes \(staged.count)", .Blue), events, open, content) + [EmptyLine()]
}

func renderLog(_ title: String, _ model: StatusModel, _ log: [GitCommit]) -> [Node] {
    let open = model.visibility["recent", default: true]
    let events: [ViewEvent<Message>] = [
        (.tab, .UpdateStatus("recent", model)),
    ]
    return collapsible(FormattedText(title, .Blue), events, open, log.map(commitMapper))
}

func commitMapper(_ commit: GitCommit) -> Text<Message> {
    let message = commit.refName
        .fold(constant(FormattedText(" "))) { name in FormattedText(" \(name) ", .Cyan) } + commit.message
    return Text(FormattedText(commit.hash.short, .LightGray) + message, [(.enter, .GitCommand(.GetCommit(commit.hash.full)))])
}

func untrackedMapper(_ untracked: Untracked) -> Node {
    let events: [ViewEvent<Message>] = [
        (.s, .GitCommand(.Stage(.File(untracked.file, .Untracked)))),
        (.u, .GitCommand(.Unstage(.File(untracked.file, .Untracked)))),
        (.x, .Info(.Query("Trash \(untracked.file)? (y or n)", .GitCommand(.Discard(.File(untracked.file, .Untracked)))))),
        (.enter, .ViewFile(untracked.file)),
    ]

    return Text(untracked.file, events)
}

func unstagedMapper(_ model: StatusModel) -> (Unstaged) -> [Node] {
    { unstaged in
        let open = model.visibility["unstaged-\(unstaged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .GitCommand(.Stage(.File(unstaged.file, .Unstaged)))),
            (.u, .GitCommand(.Unstage(.File(unstaged.file, .Unstaged)))),
            (.x, .Info(.Query("Discard unstaged changes in \(unstaged.file) (y or n)", .GitCommand(.Discard(.File(unstaged.file, .Unstaged)))))),
            (.tab, .UpdateStatus("unstaged-\(unstaged.file)", model)),
            (.enter, .ViewFile(unstaged.file)),
        ]

        let hunks = unstaged.diff.flatMap { renderHunk($0, makeHunkEvents($0.patch, .Unstaged)) }

        switch unstaged.status {
        case .Modified:
            return collapsible("modified \(unstaged.file)", events, open, hunks)

        case .Deleted:
            return collapsible("deleted \(unstaged.file)", events, open, hunks)

        case .Added:
            return collapsible("new file \(unstaged.file)", events, open, hunks)

        case let .Renamed(target):
            return collapsible("renamed \(unstaged.file) -> \(target)", events, open, hunks)

        case .Copied:
            return collapsible("copied \(unstaged.file)", events, open, hunks)

        default:
            return [Text("Unknown status \(unstaged.status): \(unstaged.file)")]
        }
    }
}

func stagedMapper(_ model: StatusModel) -> (Staged) -> [Node] {
    { staged in
        let open = model.visibility["staged-\(staged.file)", default: false]
        let events: [ViewEvent<Message>] = [
            (.s, .GitCommand(.Stage(.File(staged.file, .Staged)))),
            (.u, .GitCommand(.Unstage(.File(staged.file, .Staged)))),
            (.x, .Info(.Query("Discard staged changes in \(staged.file)? (y or n)", .GitCommand(.Discard(.File(staged.file, .Staged)))))),
            (.tab, .UpdateStatus("staged-\(staged.file)", model)),
            (.enter, .ViewFile(staged.file)),
        ]
        let hunks = staged.diff.flatMap { renderHunk($0, makeHunkEvents($0.patch, .Staged)) }
        switch staged.status {
        case .Added:
            return collapsible("new file \(staged.file)", events, open, hunks)

        case .Untracked:
            return collapsible(staged.file, events, open, hunks)

        case .Modified:
            return collapsible("modified \(staged.file)", events, open, hunks)

        case .Deleted:
            return collapsible("deleted \(staged.file)", events, open, hunks)

        case let .Renamed(target):
            return collapsible("renamed \(staged.file) -> \(target)", events, open, hunks)

        case .Copied:
            return collapsible("copied    \(staged.file)", events, open, hunks)
        }
    }
}

func renderStash(_ model: StatusModel, _ stash: [Stash]) -> [Node] {
    let open = model.visibility["stash", default: false]
    let stashes = stash.map { Text("stash@{\($0.stashIndex)}: \($0.message)")}
    return collapsible("Stashes (\(stash.count))", [], open, stashes)
}

func makeHunkEvents(_ patch: String, _ status: Status) -> [ViewEvent<Message>] {
    [
        (.s, .GitCommand(.Stage(.Hunk(patch, status)))),
        (.u, .GitCommand(.Unstage(.Hunk(patch, status)))),
        (.x, .Info(.Query("Discard hunk? (y or n)", .GitCommand(.Discard(.Hunk(patch, status)))))),
    ]
}
