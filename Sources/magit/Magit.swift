import Foundation
import Ashen
import os.log

struct Magit: Program {
    enum Message {
        case quit
        case setStatus(AsyncData<StatusInfo>)
        case refresh
    }

    struct Model {
        var status: AsyncData<StatusInfo> = .loading
    }

    func initial() -> (Model, [Command]) {
        let getStatus = Status(onResult: {result in Message.setStatus(result)})
        return (Model(status: .loading), [getStatus])
    }

    func update(model: inout Model, message: Message) -> Update<Model> {
        switch message {
        case .quit:
            return .quit
        case .setStatus(let status):
            model.status = status
        case .refresh:
            let (_, command) = initial()
            return .update(model, command)
        }

        return .model(model)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let components = renderStatus(status: model.status, screenSize: screenSize)

        return Window(
            components: components + [OnKeyPress(.q, {Message.quit}), OnKeyPress(.g, { Message.refresh })]
        )
    }
}
