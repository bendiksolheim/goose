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
}

struct Model: Equatable {
    let status: AsyncData<StatusInfo>
}

func initialize() -> (Model, Cmd<Message>) {
    return (Model(status: .loading), task(getStatus))
}

func render(model: Model) -> [AttrCharType] {
    return ["Hello"]
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case .gotStatus(let status):
        return (Model(status: status), .none)
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

run(initialize: initialize, render: render, update: update)
