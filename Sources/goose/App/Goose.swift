import Foundation
import GitLib
import tea
import os.log

indirect enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case keyboard(KeyEvent)
    case stage(Type)
    case stagePatch(String)
    case unstage(Type)
    case updateVisibility([String : Bool])
    case commandSuccess
    case info(InfoMessage)
    case clearInfo
    case queryResult(QueryResult)
    case container(ScrollMessage)
}

enum QueryResult {
    case Abort
    case Perform(Cmd<Message>)
}

enum Type {
    case untracked([Untracked])
    case unstaged([Unstaged])
    case staged([Staged])
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
        return model.keyMap[event, model]
        
    case .stage(let changes):
        return stage(model, changes)
        
    case .stagePatch(let patch):
        return (model, task({ apply(patch: patch) }))
        
    case .unstage(let changes):
        return unstage(model, changes)
        
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
        case .Perform(let cmd):
            return (model.copy(withInfo: .None, withKeyMap: normalMap), cmd)
        }

    case .container(let containerMsg):
        return (model.copy(withContainer: ScrollView<Message>.update(containerMsg, model.container)), .none)
    }
}

func stage(_ model: Model, _ type: Type) -> (Model, Cmd<Message>) {
    switch type {
    case .untracked(let untracked):
        return (model, task({ addFile(files: untracked.map { $0.file }) }))
    case .unstaged(let unstaged):
        return (model, task({ addFile(files: unstaged.map { $0.file }) }))
    case .staged(_):
        return (model, .cmd(.info(.Info("Already staged"))))
    }
}

func unstage(_ model: Model, _ type: Type) -> (Model, Cmd<Message>) {
    switch type {
    case .untracked(_):
        return (model, .cmd(.info(.Info("Already unstaged"))))
    case .unstaged(_):
        return (model, .cmd(.info(.Info("Already unstaged"))))
    case .staged(let staged):
        return (model, task({ resetFile(files: staged.map { $0.file }) }))
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

func queryMap(_ cmd: Cmd<Message>) -> KeyMap {
    return KeyMap([
        .y : { ($0, .cmd(.queryResult(.Perform(cmd)))) },
        .n : { ($0, .cmd(.queryResult(.Abort))) }
    ])
}

let subscriptions: [Sub<Message>] = [
    cursor { .container($0) },
    keyboard({ event in .keyboard(event) })
]
