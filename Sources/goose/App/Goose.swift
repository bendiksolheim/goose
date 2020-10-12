import Foundation
import Bow
import GitLib
import tea

indirect enum Message {
    case Keyboard(KeyEvent)
    case Action(Action)
    case GitCommand(GitCmd)
    case GitResult([GitLogEntry], GitResult)
    case UpdateStatus(String, StatusModel)
    case UpdateGitLog(String)
    case UserInitiatedGitCommandResult(Either<Error, ProcessResult>, Bool)
    case CommandSuccess
    case Info(InfoMessage)
    case ClearInfo
    case QueryResult(QueryResult)
    case ViewFile(String)
    case Container(ScrollMessage)
    case DropBuffer
}

enum GitCmd {
    case Status
    case GetCommit(String)
    case Stage(Selection)
    case Unstage(Selection)
    case Discard(Selection)
}

enum QueryResult {
    case Abort
    case Perform(Message)
}

enum Selection {
    case Section([String], Status)
    case File(String, Status)
    case Hunk(String, Status)
}

enum Status {
    case Untracked
    case Unstaged
    case Staged
}

enum GitResult {
    case GotStatus(AsyncData<StatusInfo>)
    case GotLog(AsyncData<LogInfo>)
    case GotCommit(String, AsyncData<CommitInfo>)
}

enum Action {
    case KeyMap(KeyMap)
    case Log
    case GitLog
    case Refresh
    case Commit
    case AmendCommit
    case Push
    case Pull
}

func initialize(basePath: String) -> () -> (Model, Cmd<Message>) {
    return {
        let git = Git(path: basePath)
        return (Model(git: git,
                      buffer: [.StatusBuffer(StatusModel(info: .Loading, visibility: [:]))],
                      info: .None,
                      scrollState: ScrollView<Message>.initialState(),
                      keyMap: statusMap,
                      gitLog: GitLogModel()),
                Task { getStatus(git: git) }.perform())
    }
}

func render(model: Model) -> Window<Message> {
    let buffer = model.buffer.last!
    let content: [View<Message>]
    switch buffer {
    case let .StatusBuffer(statusModel):
        content = renderStatus(model: statusModel)
    case let .LogBuffer(log):
        content = renderLog(log: log)
    case .GitLogBuffer:
        content = renderGitLog(gitLog: model.gitLog)
    case let .CommitBuffer(commitModel):
        content = renderDiff(diff: commitModel)
    }

    return Window(content:
        [ScrollView(content, layoutPolicy: LayoutPolicy(width: .Flexible, height: .Flexible), model.scrollState), renderInfoLine(info: model.info)]
    )
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    Logger.log("Message: \(message)")
    switch message {
    case let .Keyboard(event):
        if let message = model.keyMap[event] {
            return (model, Cmd.message(message))
        } else {
            return (model, Cmd.none())
        }

    case let .Action(action):
        return performAction(action, model)

    case let .GitCommand(command):
        return performCommand(model, command)

    case let .GitResult(log, result):
        return updateGitResult(model.with(gitLog: model.gitLog.append(log)), result)

    case let .UpdateStatus(file, status):
        return (model.replace(buffer: .StatusBuffer(status.toggle(file: file))), Cmd.none())
        
    case let .UpdateGitLog(file):
        return (model.with(gitLog: model.gitLog.toggle(file: file)), Cmd.none())
        
    case let .UserInitiatedGitCommandResult(result, showStatus):
        let modelAndCmd = result.fold(
            { error in (model.with(keyMap: statusMap), Cmd.message(Message.Info(.Message(error.localizedDescription)))) },
            { success in
                let newModel = model.with(keyMap: statusMap, gitLog: model.gitLog.append([GitLogEntry(success)]))
                if showStatus {
                    let message = Cmd.message(Message.Info(.Message(getResultMessage(success))))
                    return (newModel, Cmd.batch(message, Task { getStatus(git: model.git) }.perform()))
                } else {
                    return (newModel, Task { getStatus(git: model.git) }.perform())
                }
                
            }
        )
        return modelAndCmd

    case .CommandSuccess:
        return (model.with(keyMap: statusMap), Task { getStatus(git: model.git) }.perform())

    case let .Info(info):
        switch info {
        case .Message:
            return (model.with(info: info), TProcess.sleep(5.0).perform { Message.ClearInfo })
        case let .Query(_, cmd):
            return (model.with(info: info, keyMap: queryMap(cmd)), Cmd.none())
        default:
            return (model.with(info: info), Cmd.none())
        }

    case .ClearInfo:
        return (model.with(info: .None), Cmd.none())

    case let .QueryResult(queryResult):
        switch queryResult {
        case .Abort:
            return (model.with(info: .None, keyMap: statusMap), Cmd.none())
        case let .Perform(msg):
            return (model.with(info: .None, keyMap: statusMap), Cmd.message(msg))
        }

    case let .ViewFile(file):
        return (model, TProcess.spawn { view(file: file) }.perform { $0 })

    case let .Container(containerMsg):
        return (model.with(scrollState: ScrollView<Message>.update(containerMsg, model.scrollState)), Cmd.none())

    case .DropBuffer:
        return model.buffer.count > 1 ? (model.back(), Cmd.none()) : (model, TProcess.quit())
    }
}

func updateGitResult(_ model: Model, _ gitResult: GitResult) -> (Model, Cmd<Message>) {
    switch gitResult {
    case let .GotStatus(newStatus):
        return (model.replace(buffer: .StatusBuffer(StatusModel(info: newStatus, visibility: [:]))), Cmd.none())

    case let .GotLog(log):
        return (model.replace(buffer: .LogBuffer(log)), Cmd.none())

    case let .GotCommit(ref, commit):
        return (model.replace(buffer: .CommitBuffer(DiffModel(hash: ref, commit: commit))), Cmd.none())
    }
}

func performCommand(_ model: Model, _ gitCommand: GitCmd) -> (Model, Cmd<Message>) {
    switch gitCommand {
    case .Status:
        return (model.navigate(to: .StatusBuffer(StatusModel(info: .Loading, visibility: [:]))), Task { getStatus(git: model.git) }.perform())

    case let .GetCommit(ref):
        return (model.navigate(to: .CommitBuffer(DiffModel(hash: ref, commit: .Loading))), Task { getDiff(git: model.git, ref) }.perform())

    case let .Stage(selection):
        switch selection {
        case let .Section(files, status):
            return (model, stage(model, files, status))
        case let .File(file, status):
            return (model, stage(model, [file], status))
        case let .Hunk(hunk, status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, performGitCommand(model.git.apply(reverse: false, cached: true), hunk).perform())
            case .Staged:
                return (model, Cmd.message(.Info(.Message("Already staged"))))
            }
        }

    case let .Unstage(selection):
        switch selection {
        case let .Section(files, status):
            return (model, unstage(model, files, status))
        case let .File(file, status):
            return (model, unstage(model, [file], status))
        case let .Hunk(patch, status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, Cmd.message(.Info(.Message("Already unstaged"))))
            case .Staged:
                return (model, performGitCommand(model.git.apply(reverse: true, cached: true), patch).perform())
            }
        }

    case let .Discard(selection):
        switch selection {
        case let .Section(files, status):
            return (model, discard(model, files, status))

        case let .File(file, status):
            return (model, discard(model, [file], status))

        case let .Hunk(patch, status):
            switch status {
            case .Untracked:
                return (model, Cmd.none()) // Impossible state, untracked files does not have hunks
            case .Unstaged:
                return (model, performGitCommand(model.git.apply(reverse: true, cached: false), patch).perform())
            case .Staged:
                let unstage = performGitCommand(model.git.apply(reverse: true, cached: true), patch)
                let remove = performGitCommand(model.git.apply(reverse: true, cached: false), patch)
                let command = Task.sequence([unstage, remove]).perform { $0.last! }
                return (model, command)
            }
        }
    }
}

func stage(_ model: Model, _ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return performGitCommand(model.git.add(files)).perform()
    case .Unstaged:
        return performGitCommand(model.git.add(files)).perform()
    case .Staged:
        return Cmd.message(.Info(.Message("Already staged")))
    }
}

func unstage(_ model: Model, _ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Cmd.message(.Info(.Message("Already unstaged")))
    case .Unstaged:
        return Cmd.message(.Info(.Message("Already unstaged")))
    case .Staged:
        return performGitCommand(model.git.reset(files)).perform()
    }
}

func discard(_ model: Model, _ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Task { remove(files: files) }.perform()
    case .Unstaged:
        return performGitCommand(model.git.checkout(files: files)).perform()
    case .Staged:
        let restore = performGitCommand(model.git.restore(files, staged: true))
        let checkout = performGitCommand(model.git.checkout(files: files))
        return Task.sequence([restore, checkout]).perform { $0.last! }
    }
}

func performAction(_ action: Action, _ model: Model) -> (Model, Cmd<Message>) {
    switch action {
    case let .KeyMap(keyMap):
        return (model.with(keyMap: keyMap), Cmd.none())

    case .Commit:
        return (model, TProcess.spawn { commit() }.perform())

    case .AmendCommit:
        return (model, TProcess.spawn { commit(amend: true) }.perform())

    case .Log:
        return (model.navigate(to: .LogBuffer(.Loading)), Task { getLog(git: model.git) }.perform())

    case .GitLog:
        return (model.navigate(to: .GitLogBuffer), Cmd.none())

    case .Refresh:
        return (model, Task { getStatus(git: model.git) }.perform())

    case .Push:
        let (message, task) = performAndShowGitCommand(model.git.push())
        return (model, Cmd.batch(Cmd.message(message), task.perform()))
        
    case .Pull:
        let (message, task) = performAndShowGitCommand(model.git.pull())
        return (model, Cmd.batch(Cmd.message(message), task.perform()))
    }
}

let subscriptions: [Sub<Message>] = [
    cursor { .Container($0) },
    keyboard { event in .Keyboard(event) },
]
