import BowEffects
import GitLib
import Termbox
import os.log
//import Ashen


/*let app = App(program: Magit(), screen: TermboxScreen())
let exitState = app.run()

switch exitState {
case .quit: exit(EX_OK)
case .error: exit(EX_IOERR)
}*/

enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case cursorUpdate(UInt, UInt)
}

struct CursorModel: Equatable {
    let x: UInt
    let y: UInt
    
    init(_ x: UInt, _ y: UInt) {
        self.x = x
        self.y = y
    }
}

struct Model: Equatable {
    let status: AsyncData<StatusInfo>
    let cursor: CursorModel
}

func initialize() -> (Model, Cmd<Message>) {
    return (Model(status: .loading, cursor: CursorModel(0, 0)), task(getStatus))
}

func render(model: Model) -> [Line] {
    return renderStatus(status: model.status)
    //return [Line(Text("Hello", [.foreground(Color.blue), .background(Color.green)]))]
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case .gotStatus(let status):
        return (Model(status: status, cursor: model.cursor), .none)
    case .cursorUpdate(let x, let y):
        return (Model(status: model.status, cursor: CursorModel(x, y)), .none)
    }
}

func getStatus() -> Message {
    let tasks = IO.parZip (execute(process: ProcessDescription.git(Git.branchName())),
                           execute(process: ProcessDescription.git(Git.status())).flatMap({ result in parseStatus(result.output).fold(IO.raiseError, IO.pure) }),
                           execute(process: ProcessDescription.git(Git.log(num: 10)))
        )^
    let result = tasks.unsafeRunSyncEither()
    let status = result.fold(error, success)
    return .gotStatus(status)
}

func error(error: Error) -> AsyncData<StatusInfo> {
    return .error(error)
}

func success(branch: ProcessResult, status: GitStatus, log: ProcessResult) -> AsyncData<StatusInfo> {
    let branch = branch.output
    let log = parseCommits(log.output)
    
    return .success(StatusInfo(
        branch: branch,
        changes: status.changes,
        log: log
    ))
}

let subscriptions = [
    cursor({ (x, y) in Message.cursorUpdate(x, y) })
]

run(initialize: initialize, render: render, update: update, subscriptions: subscriptions)
