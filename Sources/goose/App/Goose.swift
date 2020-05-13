import Foundation
import GitLib
import tea
import os.log

enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case keyboard(KeyEvent)
    case stage(Type)
    case unstage(Type)
    case updateVisibility([String : Bool])
    case commandSuccess
    case info(String)
    case container(ContainerMessage)
}

enum Type {
    case untracked([Untracked])
    case unstaged([Unstaged])
    case staged([Staged])
}

func initialize() -> (Model, Cmd<Message>) {
    let statusModel = StatusModel(info: .loading, visibility: [:])
    return (Model(views: [.status], status: statusModel, log: .loading, info: "", container: Container<Message>.initialState()), task(getStatus))
}


func render(model: Model) -> Window<Message> {
    let view = model.views.last!
    let content: [Renderable<Message>]
    switch view {
    case .status:
        content = renderStatus(model: model.status)
    case .log:
        content = renderLog(log: model.log)
    }
    
    return Window(content:
        [Container(content, layoutPolicy: LayoutPolicy(width: .Flexible, height: .Flexible), model.container), TextLine(model.info)]
    )
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case .gotStatus(let newStatus):
        return (model.copy(withStatus: StatusModel(info: newStatus, visibility: model.status.visibility)), .none)
        
    case .gotLog(let log):
        return (model.copy(withLog: log), .none)
        
    case .keyboard(let event):
        return parseKey(event, model: model)
        
    case .stage(let changes):
        return stage(model, changes)
        
    case .unstage(let changes):
        return unstage(model, changes)
        
    case .updateVisibility(let visibility):
        return (model.copy(withStatus: model.status.copy(withVisibility: visibility)), .none)
        
    case .commandSuccess:
        return (model, task(getStatus))
        
    case .info(let error):
        return (model.copy(withInfo: error), .none)

    case .container(let containerMsg):
        return (model.copy(withContainer: Container<Message>.update(containerMsg, model.container)), .none)
    }
}

func stage(_ model: Model, _ type: Type) -> (Model, Cmd<Message>) {
    switch type {
    case .untracked(let untracked):
        return (model, task({ addFile(files: untracked.map { $0.file }) }))
    case .unstaged(let unstaged):
        return (model, task({ addFile(files: unstaged.map { $0.file }) }))
    case .staged(_):
        return (model, .cmd(.info("Already staged")))
    }
}

func unstage(_ model: Model, _ type: Type) -> (Model, Cmd<Message>) {
    switch type {
    case .untracked(_):
        return (model, .cmd(.info("Already unstaged")))
    case .unstaged(_):
        return (model, .cmd(.info("Already unstaged")))
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

let subscriptions: [Sub<Message>] = [
    cursor { .container($0) },
    keyboard({ event in .keyboard(event) })
]
