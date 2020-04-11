import Foundation
import Ashen
import os.log

enum View {
    case status
    case log
}

struct Magit: Program {
    enum Message {
        case close
        case setStatus(AsyncData<StatusInfo>)
        case setLog(AsyncData<LogInfo>)
        case viewLog
        case refresh
    }

    struct Model {
        var status: AsyncData<StatusInfo> = .loading
        var log: AsyncData<LogInfo> = .loading
        var views: [View]
    }

    func initial() -> (Model, [Command]) {
        let getStatus = Status(onResult: {result in Message.setStatus(result)})
        return (Model(status: .loading, views: [.status]), [getStatus])
    }

    func update(model: inout Model, message: Message) -> Update<Model> {
        switch message {
        case .close:
            if model.views.count > 1 {
                model.views.removeLast()
                return .update(model, [])
            } else {
                return .quit
            }
        case .setStatus(let status):
            model.status = status
        case .setLog(let log):
            model.log = log
        case .viewLog:
            model.views.append(.log)
            return .update(model, [Log(onResult: { Message.setLog($0) })])
        case .refresh:
            let (_, command) = initial()
            return .update(model, command)
        }

        return .model(model)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let view = model.views.last!
        let components: [Component]
        switch view {
        case .status:
            components = renderStatus(status: model.status, screenSize: screenSize)
        case .log:
            components = renderLog(log: model.log, screenSize: screenSize)
        }

        return Window(
            components: components +
                [OnKeyPress(.q, { Message.close }),
                 OnKeyPress(.g, { Message.refresh }),
                 OnKeyPress(.l, { Message.viewLog })
                ]
        )
    }
}
