import Darwin
import Ashen
import os.log
import BowEffects

//public class Cmd: Command {
//    
//    public typealias OnResult = (String) -> AnyMessage
//    
//    let process: ProcessDescription
//    let onResult: OnResult
//    
//    public init(process: ProcessDescription, onResult: @escaping OnResult) {
//        self.process = process
//        self.onResult = onResult
//    }
//    
//    static func run(process: ProcessDescription, onResult: @escaping OnResult) -> Cmd {
//        Cmd(process: process, onResult: onResult)
//    }
//    
//    public func start(_ send: @escaping (AnyMessage) -> Void) {
//        let task = execute(process: self.process)
//        let result = task.unsafeRunSyncEither(on: .global(qos: .background))
//        let branch = result.fold({ error in error.localizedDescription }, { result in result.output})
//        let message = self.onResult(branch)
//        send(message)
//    }
//}

struct Magit: Program {
    enum Message {
        case quit
        case setStatus(StatusEnum)
    }

    struct Model {
        var status: StatusEnum = .loading
    }

    func initial() -> (Model, [Command]) {
        //let getBranch = Cmd.run(process: branchName(), onResult: { branchName in Message.setBranch(branchName)})
        let getStatus = Status(onResult: {result in Message.setStatus(result)})
        return (Model(status: .loading), [getStatus])
    }

    func update(model: inout Model, message: Message) -> Update<Model> {
        switch message {
        case .quit:
            return .quit
        case let .setStatus(status):
            model.status = status
        }
        
        return .model(model)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let components: [Component]
        switch model.status {
        case .loading:
            components = [LabelView(at: .topLeft(), text: "Loading...")]
        case .error(let error):
            components = [LabelView(at: .topLeft(), text: error.localizedDescription)]
        case .success(let status):
            let untracked = status.changes.filter(isUntracked)
            let unstaged = status.changes.filter(isUnstaged)
            let staged = status.changes.filter(isStaged)
            components = [
                FlowLayout.vertical(size: DesiredSize(width: screenSize.width, height: screenSize.height), components: [
                    Section(title: .LabelView(LabelView(text: "Head:     " + Text(status.branch, [.foreground(Color.cyan)]) + " " + status.log[0].message)), items: [], itemMapper: { $0 }, open: true, screenSize: screenSize),
                    Section(title: .String("Untracked files (\(untracked.count))"), items: untracked, itemMapper: changeMapper, open: true, screenSize: screenSize),
                    Section(title: .String("Unstaged changes (\(unstaged.count))"), items: unstaged, itemMapper: changeMapper, open: true, screenSize: screenSize),
                    Section(title: .String("Staged changes (\(staged.count))"), items: staged, itemMapper: changeMapper, open: true, screenSize: screenSize),
                    Section(title: .String("Recent commits"), items: status.log, itemMapper: commitMapper, open: true, screenSize: screenSize)
                ])
            ]
        }
        
        return Window(
          components: components + [OnKeyPress(.q, {Message.quit})]
        )
    }
}

func commitMapper(_ commit: GitCommit) -> LabelView {
    LabelView(text: Text(commit.hash.short, [.foreground(.any(241))]) + " \(commit.message)")
}

func changeMapper(_ change: Change) -> LabelView {
    switch change.status {
    case .Added:
        return LabelView(text: "new file  \(change.file)")
    case .Untracked:
        return LabelView(text: change.file)
    case .Modified:
        return LabelView(text: "modified  \(change.file)")
    case .Deleted:
        return LabelView(text: "modified  \(change.file)")
    case .Renamed:
        return LabelView(text: "renamed   \(change.file)")
    case .Copied:
        return LabelView(text: "copied    \(change.file)")
    }
}


let app = App(program: Magit(), screen: TermboxScreen())
let exitState = app.run()

switch exitState {
case .quit: exit(EX_OK)
case .error: exit(EX_IOERR)
}

