import Foundation
import os.log

enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case cursorUpdate(UInt, UInt)
    case keyboard(KeyEvent)
}

func initialize() -> (Model, Cmd<Message>) {
    return (Model(views: [.status], status: .loading, log: .loading, cursor: CursorModel(0, 0)), task(getStatus))
}

func render(model: Model) -> [Line] {
    let view = model.views.last!
    switch view {
    case .status:
        return renderStatus(status: model.status)
    case .log:
        return renderLog(log: model.log)
    }
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case .gotStatus(let newStatus):
        return (model.copy(withStatus: newStatus), .none)
    case .gotLog(let log):
        return (model.copy(withLog: log), .none)
    case .cursorUpdate(let x, let y):
        return (model.copy(withCursor: CursorModel(x, y)), .none)
    case .keyboard(let event):
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
        default:
            return (model, .none)
        }
    }
}

let subscriptions = [
    cursor({ (x, y) in Message.cursorUpdate(x, y) }),
    keyboard({ event in .keyboard(event) })
]
