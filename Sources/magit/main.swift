import Darwin
import Ashen

public class Cmd: Command {
    
    public typealias Runner = () -> String
    public typealias OnResult = (String) -> AnyMessage
    
    let runner: Runner
    let onResult: OnResult
    
    public init(runner: @escaping Runner, onResult: @escaping OnResult) {
        self.runner = runner
        self.onResult = onResult
    }
    
    static func run(runner: @escaping Runner, onResult: @escaping OnResult) -> Cmd {
        Cmd(runner: runner, onResult: onResult)
    }
    
    public func start(_ send: @escaping (AnyMessage) -> Void) {
        let result = self.runner()
        let message = self.onResult(result)
        send(message)
    }
    
    
}

struct Magit: Program {
    enum Message {
        case quit
        case setBranch(String)
    }

    struct Model {
        var branch = ""
    }

    func initial() -> (Model, [Command]) {
        let getBranch = Cmd.run(runner: { branchName() }, onResult: { branchName in Message.setBranch(branchName)})
        return (Model(), [getBranch])
    }

    func update(model: inout Model, message: Message) -> Update<Model> {
        switch message {
        case .quit:
            return .quit
        case let .setBranch(branch):
            model.branch = branch
        }
        
        return .model(model)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        return Window(
          components: [
            LabelView(at: .topLeft(), text: "Head:\t\t\(model.branch)"),
            OnKeyPress(.q, { Message.quit })
          ]
        )
    }
}

let app = App(program: Magit(), screen: TermboxScreen())
let exitState = app.run()

switch exitState {
case .quit: exit(EX_OK)
case .error: exit(EX_IOERR)
}
