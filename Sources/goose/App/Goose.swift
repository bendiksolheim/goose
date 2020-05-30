import Foundation
import GitLib
import tea
import os.log

indirect enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case keyboard(KeyEvent)
    case gitCommand(GitCmd)
    case updateVisibility([String : Bool])
    case commandSuccess
    case info(InfoMessage)
    case clearInfo
    case queryResult(QueryResult)
    case container(ScrollMessage)
}

enum GitCmd {
    case Stage(Selection)
    //case StagePatch(String)
    case Unstage(Selection)
    case Discard(Selection)
    case Remove(String)
    case Checkout(String)
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

func initialize() -> (Model, Cmd<Message>) {
    let statusModel = StatusModel(info: .loading, visibility: [:])
    return (Model(views: [.status], status: statusModel, log: .loading, info: .None, container: ScrollView<Message>.initialState(), keyMap: normalMap), task(getStatus))
}


func render(model: Model) -> Window<Message> {
    let view = model.views.last!
    let content: [View<Message>]
    switch view {
    case .status:
        content = renderStatus(model: model.status)
    case .log:
        content = renderLog(log: model.log)
    }
    
    return Window(content:
        [ScrollView(content, layoutPolicy: LayoutPolicy(width: .Flexible, height: .Flexible), model.container), renderInfoLine(info: model.info)]
    )
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case .gotStatus(let newStatus):
        return (model.copy(withStatus: StatusModel(info: newStatus, visibility: model.status.visibility)), .none)
        
    case .gotLog(let log):
        return (model.copy(withLog: log), .none)
        
    case .keyboard(let event):
        return model.keyMap[event, model](model)
        
    case .gitCommand(let command):
        return performCommand(model, command)
        
    case .updateVisibility(let visibility):
        return (model.copy(withStatus: model.status.copy(withVisibility: visibility)), .none)
        
    case .commandSuccess:
        return (model, task(getStatus))
        
    case .info(let info):
        switch info {
        case .Info(_):
            return (model.copy(withInfo: info), .delayedTask(5.0, { .clearInfo }))
        case .Query(_, let cmd):
            return (model.copy(withInfo: info, withKeyMap: queryMap(cmd)), .none)
        default:
            return (model.copy(withInfo: info), .none)
        }
        
    case .clearInfo:
        return (model.copy(withInfo: .None), .none)
        
    case .queryResult(let queryResult):
        switch queryResult {
        case .Abort:
            return (model.copy(withInfo: .None, withKeyMap: normalMap), .none)
        case .Perform(let msg):
            return (model.copy(withInfo: .None, withKeyMap: normalMap), .cmd(msg))
        }

    case .container(let containerMsg):
        return (model.copy(withContainer: ScrollView<Message>.update(containerMsg, model.container)), .none)
    }
}

func performCommand(_ model: Model, _ gitCommand: GitCmd) -> (Model, Cmd<Message>) {
    switch gitCommand {
    case .Stage(let selection):
        switch selection {
        case .Section(let files, let status):
            return (model, stage(files, status))
        case .File(let file, let status):
            return (model, stage([file], status))
        case .Hunk(let hunk, let status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, task({ apply(patch: hunk) }))
            case .Staged:
                return (model, .cmd(.info(.Info("Already staged"))))
            }
        }
        
    case .Unstage(let selection):
        switch selection {
        case .Section(let files, let status):
            return (model, unstage(files, status))
        case .File(let file, let status):
            return (model, unstage([file], status))
        case .Hunk(let patch, let status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, .cmd(.info(.Info("Already unstaged"))))
            case .Staged:
                return (model, .none) //TODO: implement unstaging of hunks
            }
        }
        
    case .Discard(let selection):
        switch selection {
        case .Section(let files, let status):
            return (model, .none) //TODO: implement discarding of sections
        case .File(let file, let status):
            switch status {
            case .Untracked:
                return (model, task({ remove(file: file) }))
            case .Unstaged:
                return (model, .none) //TODO: implement discarding of unstaged file
            case .Staged:
                return (model, .none) //TODO: implement discarding of staged file
            }
        case .Hunk(let patch, let status):
            return (model, .none) //TODO: implement discarding of hunks
        }
        
    case .Checkout(let file):
        return (model, task({ checkout(file: file) }))
        
    case .Remove(let file):
        return (model, task({ remove(file: file) }))
    }
}

func stage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return task({ addFile(files: files) })
    case .Unstaged:
        return task({ addFile(files: files) })
    case .Staged:
        return .cmd(.info(.Info("Already staged")))
    }
}

func unstage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return .cmd(.info(.Info("Already unstaged")))
    case .Unstaged:
        return .cmd(.info(.Info("Already unstaged")))
    case .Staged:
        return task({ resetFile(files: files) })
    }
}

func parseKey(_ event: KeyEvent, model: Model) -> (Model, Cmd<Message>) {
    switch event {
    case .q:
        if model.views.count > 1 {
            return (model.popView(), .none)
        } else {
            return (model, .exit)
        }
    case .l:
        return (model.pushView(view: .log), task(getLog))
        
    case .g:
        return (model, task(getStatus))
        
    case .c:
        return (model, process(commit))
        
    default:
        return (model, .none)
    }
}

let normalMap = KeyMap([
    .q : { $0.views.count > 1 ? ($0.popView(), .none) : ($0, .exit) },
    .l : { ($0.pushView(view: .log), task(getLog)) },
    .g : { ($0, task(getStatus)) },
    .c : { ($0, process(commit)) },
])

func queryMap(_ msg: Message) -> KeyMap {
    return KeyMap([
        .y : { ($0, .cmd(.queryResult(.Perform(msg)))) },
        .n : { ($0, .cmd(.queryResult(.Abort))) },
        .q : { ($0, .cmd(.queryResult(.Abort))) },
        .esc : { ($0, .cmd(.queryResult(.Abort))) }
    ])
}

let subscriptions: [Sub<Message>] = [
    cursor { .container($0) },
    keyboard({ event in .keyboard(event) })
]
