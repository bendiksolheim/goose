import Darwin
import Ashen
import os.log
import Bow
import BowEffects
import GitLib

struct Magit: Program {
    enum Message {
        case quit
        case setStatus(StatusEnum)
        case refresh
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
        case .setStatus(let status):
            model.status = status
        case .refresh:
            let (_, command) = initial()
            return .update(model, command)
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
            var sections: [Component] = [Section(title: .LabelView(headMapper(status.log[0])), items: [], itemMapper: { $0 }, open: true, screenSize: screenSize)]
            
            let untracked = status.changes.filter(isUntracked)
            if untracked.count > 0 {
                sections.append(Section(title: .String("Untracked files (\(untracked.count))"), items: untracked, itemMapper: changeMapper, open: true, screenSize: screenSize))
            }
            
            let unstaged = status.changes.filter(isUnstaged)
            if unstaged.count > 0 {
                sections.append(Section(title: .String("Unstaged changes (\(unstaged.count))"), items: unstaged, itemMapper: changeMapper, open: true, screenSize: screenSize))
            }
            
            let staged = status.changes.filter(isStaged)
            if staged.count > 0 {
                sections.append(Section(title: .String("Staged changes (\(staged.count))"), items: staged, itemMapper: changeMapper, open: true, screenSize: screenSize))
            }
            
            sections.append(Section(title: .String("Recent commits"), items: status.log, itemMapper: commitMapper, open: true, screenSize: screenSize))
            
            components = [
                FlowLayout.vertical(size: DesiredSize(width: screenSize.width, height: screenSize.height), components: sections)
            ]
        }
        
        return Window(
            components: components + [OnKeyPress(.q, {Message.quit}), OnKeyPress(.g, { Message.refresh })]
        )
    }
}

func headMapper(_ commit: GitCommit) -> LabelView {
    let ref = commit.refName.getOrElse("")
    return LabelView(text: "Head:     " + Text(ref, [.foreground(.cyan)]) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> LabelView {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", [.foreground(.cyan)]) }) + commit.message
    return LabelView(text: Text(commit.hash.short, [.foreground(.any(241))]) + message)
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
        return LabelView(text: "deleted  \(change.file)")
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

