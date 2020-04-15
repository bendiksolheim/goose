import BowEffects
import GitLib
import Termbox
import os.log

enum View {
    case status
    case log
}

enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case cursorUpdate(UInt, UInt)
    case keyboard(KeyEvent)
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
    let views: [View]
    let status: AsyncData<StatusInfo>
    let log: AsyncData<LogInfo>
    let cursor: CursorModel
    
    func copy(withViews views: [View]? = nil,
              withStatus status: AsyncData<StatusInfo>? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withCursor cursor: CursorModel? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              cursor: cursor ?? self.cursor)
    }
    
    func pushView(view: View) -> Model {
        copy(withViews: self.views + [view])
    }
    
    func popView() -> Model {
        copy(withViews: self.views.dropLast())
    }
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
        default:
            return (model, .none)
        }
    }
}

func getLog() -> Message {
    let tasks = IO.parZip(execute(process: ProcessDescription.git(Git.branchName())),
                          execute(process: ProcessDescription.git(Git.log(num: 100))))^
    let result = tasks.unsafeRunSyncEither()
    let log: AsyncData = result.fold(error, logSuccess)
    return .gotLog(log)
}

func getStatus() -> Message {
    let tasks = IO.parZip (execute(process: ProcessDescription.git(Git.branchName())),
                           execute(process: ProcessDescription.git(Git.status())).flatMap({ result in parseStatus(result.output).fold(IO.raiseError, IO.pure) }),
                           execute(process: ProcessDescription.git(Git.log(num: 10)))
        )^
    let result = tasks.unsafeRunSyncEither()
    let status = result.fold(error, statusSuccess)
    return .gotStatus(status)
}

func error<T>(error: Error) -> AsyncData<T> {
    return .error(error)
}

func statusSuccess(branch: ProcessResult, status: GitStatus, log: ProcessResult) -> AsyncData<StatusInfo> {
    let branch = branch.output
    let log = parseCommits(log.output)
    
    return .success(StatusInfo(
        branch: branch,
        changes: status.changes,
        log: log
    ))
}

func logSuccess(branchResult: ProcessResult, logResult: ProcessResult) -> AsyncData<LogInfo> {
    let branch = branchResult.output
    let log = parseCommits(logResult.output)

    return .success(LogInfo(branch: branch, commits: log))
}

let subscriptions = [
    cursor({ (x, y) in Message.cursorUpdate(x, y) }),
    keyboard({ event in .keyboard(event) })
]

run(initialize: initialize, render: render, update: update, subscriptions: subscriptions)
