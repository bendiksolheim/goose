import Foundation
import GitLib
import os.log
import tea

indirect enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case getCommit(String)
    case gotCommit(AsyncData<GitCommit>)
    case keyboard(KeyEvent)
    case Action(Action)
    case gitCommand(GitCmd)
    case updateVisibility([String: Bool])
    case commandSuccess
    case info(InfoMessage)
    case clearInfo
    case queryResult(QueryResult)
    case ViewFile(String)
    case container(ScrollMessage)
}

enum GitCmd {
    case Stage(Selection)
    case Unstage(Selection)
    case Discard(Selection)
}

enum QueryResult {
    case Abort
    case Perform(Message)
}

enum Selection {
    case Section([String], Status)
    case File(String, Status)
    case Hunk(String, Status)
}

enum Status {
    case Untracked
    case Unstaged
    case Staged
}

enum Action {
    case KeyMap(KeyMap)
    case PopView
    case Log
    case Refresh
    case Commit
    case AmendCommit
}

func initialize() -> (Model, Cmd<Message>) {
    let statusModel = StatusModel(info: .loading, visibility: [:])
    let commitModel = CommitModel(hash: "", commit: .loading)
    return (Model(views: [.StatusView],
                  status: statusModel,
                  log: .loading,
                  commit: commitModel,
                  info: .None,
                  scrollState: ScrollView<Message>.initialState(),
                  keyMap: normalMap),
            Task { getStatus() }.perform())
}

func render(model: Model) -> Window<Message> {
    let view = model.views.last!
    let content: [View<Message>]
    switch view {
    case .StatusView:
        content = renderStatus(model: model.status)
    case .LogView:
        content = renderLog(log: model.log)
    case .CommitView:
        content = renderCommit(commit: model.commit)
    }

    return Window(content:
        [ScrollView(content, layoutPolicy: LayoutPolicy(width: .Flexible, height: .Flexible), model.scrollState), renderInfoLine(info: model.info)]
    )
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case let .gotStatus(newStatus):
        return (model.with(status: StatusModel(info: newStatus, visibility: model.status.visibility)), Cmd.none())

    case let .gotLog(log):
        return (model.with(log: log), Cmd.none())

    case let .getCommit(ref):
        return (model.with(commit: model.commit.with(hash: ref, commit: .loading)).pushView(view: .CommitView), Task { getCommit(ref) }.perform { .gotCommit($0) })

    case let .gotCommit(commit):
        return (model.with(commit: model.commit.with(commit: commit)), Cmd.none())

    case let .keyboard(event):
        if let message = model.keyMap[event] {
            return (model, Cmd.message(message))
        } else {
            return (model, Cmd.none())
        }
        
    case let .Action(action):
        os_log("%{public}@", "\(action)")
        return performAction(action, model)

    case let .gitCommand(command):
        return performCommand(model, command)

    case let .updateVisibility(visibility):
        return (model.with(status: model.status.with(visibility: visibility)), Cmd.none())

    case .commandSuccess:
        return (model.with(keyMap: normalMap), Task { getStatus() }.perform())

    case let .info(info):
        switch info {
        case .Message:
            return (model.with(info: info), TProcess.sleep(5.0).perform { Message.clearInfo })
        case let .Query(_, cmd):
            return (model.with(info: info, keyMap: queryMap(cmd)), Cmd.none())
        default:
            return (model.with(info: info), Cmd.none())
        }

    case .clearInfo:
        return (model.with(info: .None), Cmd.none())

    case let .queryResult(queryResult):
        switch queryResult {
        case .Abort:
            return (model.with(info: .None, keyMap: normalMap), Cmd.none())
        case let .Perform(msg):
            return (model.with(info: .None, keyMap: normalMap), Cmd.message(msg))
        }

    case let .ViewFile(file):
        return (model, TProcess.spawn { view(file: file) }.perform { $0 })

    case let .container(containerMsg):
        return (model.with(scrollState: ScrollView<Message>.update(containerMsg, model.scrollState)), Cmd.none())
    }
}

func performCommand(_ model: Model, _ gitCommand: GitCmd) -> (Model, Cmd<Message>) {
    switch gitCommand {
    case let .Stage(selection):
        switch selection {
        case let .Section(files, status):
            return (model, stage(files, status))
        case let .File(file, status):
            return (model, stage([file], status))
        case let .Hunk(hunk, status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, Task { apply(patch: hunk, cached: true) }.perform())
            case .Staged:
                return (model, Cmd.message(.info(.Message("Already staged"))))
            }
        }

    case let .Unstage(selection):
        switch selection {
        case let .Section(files, status):
            return (model, unstage(files, status))
        case let .File(file, status):
            return (model, unstage([file], status))
        case let .Hunk(patch, status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, Cmd.message(.info(.Message("Already unstaged"))))
            case .Staged:
                return (model, Task { apply(patch: patch, reverse: true, cached: true) }.perform())
            }
        }

    case let .Discard(selection):
        switch selection {
        case let .Section(files, status):
            return (model, discard(files, status))

        case let .File(file, status):
            return (model, discard([file], status))

        case let .Hunk(patch, status):
            switch status {
            case .Untracked:
                return (model, Cmd.none()) // Impossible state, untracked files does not have hunks
            case .Unstaged:
                return (model, Task { apply(patch: patch, reverse: true) }.perform())
            case .Staged:
                return (model, Task { apply(patch: patch, reverse: true, cached: true) }.andThen { _ in apply(patch: patch, reverse: true) }.perform())
            }
        }
    }
}

func stage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Task { addFile(files: files) }.perform()
    case .Unstaged:
        return Task { addFile(files: files) }.perform()
    case .Staged:
        return Cmd.message(.info(.Message("Already staged")))
    }
}

func unstage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Cmd.message(.info(.Message("Already unstaged")))
    case .Unstaged:
        return Cmd.message(.info(.Message("Already unstaged")))
    case .Staged:
        return Task { resetFile(files: files) }.perform()
    }
}

func discard(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Task { remove(files: files) }.perform()
    case .Unstaged:
        return Task { checkout(files: files) }.perform()
    case .Staged:
        return Task { restore(files, true) }.andThen { _ in checkout(files: files) }.perform()
    }
}

func performAction(_ action: Action, _ model: Model) -> (Model, Cmd<Message>) {
    switch action {
    case let .KeyMap(keyMap):
        return (model.with(keyMap: keyMap), Cmd.none())
        
    case .Commit:
        return (model, TProcess.spawn { commit() }.perform())
        
    case .AmendCommit:
        return (model, TProcess.spawn { commit(true) }.perform())
    
    case .Log:
        return (model.pushView(view: Views.LogView), Task { getLog() }.perform())
        
    case .PopView:
        return model.views.count > 1 ? (model.popView(), Cmd.none()) : (model, TProcess.quit())
        
    case .Refresh:
        return (model, Task { getStatus() }.perform())
    }
}

let subscriptions: [Sub<Message>] = [
    cursor { .container($0) },
    keyboard { event in .keyboard(event) },
]
