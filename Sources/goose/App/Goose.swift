import Foundation
import GitLib
import tea

indirect enum Message {
    case GotStatus(AsyncData<StatusInfo>)
    case GotLog(AsyncData<LogInfo>)
    case GetCommit(String)
    case GotCommit(String, AsyncData<GitCommit>)
    case Keyboard(KeyEvent)
    case Action(Action)
    case GitCommand(GitCmd)
    case UpdateStatus(StatusModel)
    case CommandSuccess
    case Info(InfoMessage)
    case ClearInfo
    case QueryResult(QueryResult)
    case ViewFile(String)
    case Container(ScrollMessage)
    case Exit
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
    case Log
    case Refresh
    case Commit
    case AmendCommit
    case Push
}

func initialize() -> (Model, Cmd<Message>) {
    let statusModel = StatusModel(info: .Loading, visibility: [:])
    return (Model(buffer: .StatusBuffer(statusModel),
                  log: .Loading,
                  info: .None,
                  scrollState: ScrollView<Message>.initialState(),
                  keyMap: statusMap),
            Task { getStatus() }.perform())
}

func render(model: Model) -> Window<Message> {
    let content: [View<Message>]
    switch model.buffer {
    case let .StatusBuffer(statusModel):
        content = renderStatus(model: statusModel)
    case .LogBuffer:
        content = renderLog(log: model.log)
    case let .CommitBuffer(commitModel):
        content = renderCommit(commit: commitModel)
    }

    return Window(content:
        [ScrollView(content, layoutPolicy: LayoutPolicy(width: .Flexible, height: .Flexible), model.scrollState), renderInfoLine(info: model.info)]
    )
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case let .GotStatus(newStatus):
        return (model.with(buffer: .StatusBuffer(StatusModel(info: newStatus, visibility: [:]))), Cmd.none())

    case let .GotLog(log):
        return (model.with(log: log), Cmd.none())

    case let .GetCommit(ref):
        return (model.with(buffer: .CommitBuffer(CommitModel(hash: ref, commit: .Loading))), Task { getCommit(ref) }.perform { .GotCommit(ref, $0) })

    case let .GotCommit(ref, commit):
        return (model.with(buffer: .CommitBuffer(CommitModel(hash: ref, commit: commit))), Cmd.none())

    case let .Keyboard(event):
        if let message = model.keyMap[event] {
            return (model, Cmd.message(message))
        } else {
            return (model, Cmd.none())
        }
        
    case let .Action(action):
        return performAction(action, model)

    case let .GitCommand(command):
        return performCommand(model, command)

    case let .UpdateStatus(status):
        return (model.with(buffer: .StatusBuffer(status)), Cmd.none())

    case .CommandSuccess:
        return (model.with(keyMap: statusMap), Task { getStatus() }.perform())

    case let .Info(info):
        switch info {
        case .Message:
            return (model.with(info: info), TProcess.sleep(5.0).perform { Message.ClearInfo })
        case let .Query(_, cmd):
            return (model.with(info: info, keyMap: queryMap(cmd)), Cmd.none())
        default:
            return (model.with(info: info), Cmd.none())
        }

    case .ClearInfo:
        return (model.with(info: .None), Cmd.none())

    case let .QueryResult(queryResult):
        switch queryResult {
        case .Abort:
            return (model.with(info: .None, keyMap: statusMap), Cmd.none())
        case let .Perform(msg):
            return (model.with(info: .None, keyMap: statusMap), Cmd.message(msg))
        }

    case let .ViewFile(file):
        return (model, TProcess.spawn { view(file: file) }.perform { $0 })

    case let .Container(containerMsg):
        return (model.with(scrollState: ScrollView<Message>.update(containerMsg, model.scrollState)), Cmd.none())
        
    case .Exit:
        return (model, TProcess.quit())
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
                return (model, Cmd.message(.Info(.Message("Already staged"))))
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
                return (model, Cmd.message(.Info(.Message("Already unstaged"))))
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
        return Cmd.message(.Info(.Message("Already staged")))
    }
}

func unstage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Cmd.message(.Info(.Message("Already unstaged")))
    case .Unstaged:
        return Cmd.message(.Info(.Message("Already unstaged")))
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
        return (model.with(buffer: .LogBuffer, keyMap: logMap), Task { getLog() }.perform())
        
    case .Refresh:
        return (model, Task { getStatus() }.perform())
        
    case .Push:
        return (model, Task { push() }.perform())
    }
}

let subscriptions: [Sub<Message>] = [
    cursor { .Container($0) },
    keyboard { event in .Keyboard(event) },
]
