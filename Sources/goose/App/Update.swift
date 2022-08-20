import Foundation
import Tea
import Bow
import GitLib

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    Tea.debug("Message: \(message)")
    switch message {
    case let .TerminalEvent(event):
        return terminalEventUpdate(model, event)

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

    case let .UserInitiatedGitCommandResult(result):
        return result.fold(
                { error in (model.with(keyMap: commandMap), Cmd.message(Message.Info(.Message(error.localizedDescription)))) },
                { success in
                    let newModel = model.with(keyMap: commandMap, gitLog: model.gitLog.append([GitLogEntry(success)]))
                    return (newModel, getStatus(git: model.git))
                }
        )

    case let .UserInitiatedGitComandResultShowStatus(result):
        return result.fold(
                { error in (model.with(keyMap: commandMap), Cmd.message(Message.Info(.Message(error.localizedDescription)))) },
                { success in
                    let newModel = model.with(keyMap: commandMap, gitLog: model.gitLog.append([GitLogEntry(success)]))
                    let message = Cmd.message(Message.Info(.Message(getResultMessage(success))))
                    return (newModel, Cmd.batch(message, getStatus(git: model.git)))
                }
        )

    case .CommandSuccess:
        return (model.with(keyMap: commandMap), getStatus(git: model.git))

    case let .Info(info):
        switch info {
        case .Message:
            return (model.with(info: info), Tea.sleep(5.0).perform({ _ in
                Message.ClearInfo
            }, { Message.ClearInfo }))
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
            return (model.with(info: .None, keyMap: commandMap), Cmd.none())
        case let .Perform(msg):
            return (model.with(info: .None, keyMap: commandMap), Cmd.message(msg))
        }

    case let .ViewFile(file):
        return (model, Tea.quit("view:\(file)"))

    case .DropBuffer:
        return model.views.count > 1 ? (model.back(), Cursor.put(0, 0)) : (model, Tea.quit())
    }
}

func terminalEventUpdate(_ model: Model, _ event: TerminalEvent) -> (Model, Cmd<Message>) {
    switch event {
    case let .Keyboard(event):
        if let message = model.keyMap[event] {
            return (model, Cmd.message(message))
        } else {
            return (model, getGeneralCommand(event: event))
        }
    case let .Cursor(cursor):
        return (model.replace(buffer: model.views.last!.with(cursor: cursor)), Cmd.none())
    default:
        return (model, Cmd.none())
    }
}

func updateGitResult(_ model: Model, _ gitResult: GitResult) -> (Model, Cmd<Message>) {
    switch gitResult {
    case let .GotStatus(newStatus):
        return (model.replace(buffer: .StatusBuffer(StatusModel(info: newStatus, visibility: Visibility()))), Cmd.none())

    case let .GotLog(log):
        return (model.replace(buffer: .LogBuffer(log)), Cmd.none())

    case let .GotCommit(ref, commit):
        return (model.replace(buffer: .CommitBuffer(DiffModel(hash: ref, commit: commit))), Cmd.none())
    }
}

func performCommand(_ model: Model, _ gitCommand: GitCmd) -> (Model, Cmd<Message>) {
    switch gitCommand {
    case .Status:
        return (model.navigate(to: .StatusBuffer(StatusModel(info: .Loading, visibility: Visibility()))), getStatus(git: model.git))

    case let .GetCommit(ref):
        return (model.navigate(to: .CommitBuffer(DiffModel(hash: ref, commit: .Loading))), getDiff(git: model.git, ref))

    case let .Stage(selection):
        switch selection {
        case let .Section(files, status):
            return (model, stage(model, files, status))
        case let .File(file, status):
            return (model, stage(model, [file], status))
        case let .Hunk(hunk, status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, Effect(model.git.apply(reverse: false, cached: true).exec(hunk)).perform({ .UserInitiatedGitCommandResult($0) }))
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
                return (model, Effect(model.git.apply(reverse: true, cached: true).exec(patch)).perform({ .UserInitiatedGitCommandResult($0) }))
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
                return (model, Effect(model.git.apply(reverse: true, cached: false).exec(patch)).perform({ .UserInitiatedGitCommandResult($0) }))
            case .Staged:
                let unstage = Effect(model.git.apply(reverse: true, cached: true).exec(patch))
                let remove = Effect(model.git.apply(reverse: true, cached: false).exec(patch))
                let command = Effect.sequence([unstage, remove]).perform {
                    Message.UserInitiatedGitCommandResult($0.map {
                        $0.last!
                    }^)
                }
                return (model, command)
            }
        }

    case .Stash:
        //performGit
        return (model, Cmd.none())
    }
}

func stage(_ model: Model, _ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Effect(model.git.add(files).exec()).perform({ .UserInitiatedGitCommandResult($0) })
    case .Unstaged:
        return Effect(model.git.add(files).exec()).perform({ .UserInitiatedGitCommandResult($0) })
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
        return Effect(model.git.reset(files).exec()).perform({ .UserInitiatedGitCommandResult($0) })
    }
}

func discard(_ model: Model, _ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Effect(remove(files: files)).perform({ _ in .Info(.Message("Error deleting file")) }, { $0 })
    case .Unstaged:
        return Effect(model.git.checkout(files: files).exec()).perform({ .UserInitiatedGitCommandResult($0) })
    case .Staged:
        let restore = Effect(model.git.restore(files, staged: true).exec())
        let checkout = Effect(model.git.checkout(files: files).exec())
        return Effect.sequence([restore, checkout]).perform {
            .UserInitiatedGitCommandResult($0.map {
                $0.last!
            }^)
        }
    }
}

func performAction(_ action: Action, _ model: Model) -> (Model, Cmd<Message>) {
    switch action {
    case let .ToggleKeyMap(show):
        return (model.with(renderKeyMap: show, keyMap: show ? model.keyMap : commandMap), Cmd.none())

    case let .KeyMap(keyMap):
        return (model.with(keyMap: keyMap), Cmd.none())

    case .Commit:
        return (model, Tea.quit("commit"))

    case .AmendCommit:
        return (model, Tea.quit("amend"))

    case .Log:
        return (model.navigate(to: .LogBuffer(.Loading)), getLog(git: model.git))

    case .GitLog:
        return (model.navigate(to: .GitLogBuffer), Cmd.none())

    case .Refresh:
        return (model, getStatus(git: model.git))

    case .Push:
        let gitCmd = model.git.push()
        let message = Message.Info(.Message("Running \(gitCmd.cmd())"))
        let cmd = Effect(gitCmd.exec()).perform({ Message.UserInitiatedGitComandResultShowStatus($0) })
        return (model, Cmd.batch(Cmd.message(message), cmd))

    case .Pull:
        let gitCmd = model.git.pull()
        let message = Message.Info(.Message("Running \(gitCmd.cmd())"))
        let cmd = Effect(gitCmd.exec()).perform({ Message.UserInitiatedGitComandResultShowStatus($0) })
        return (model, Cmd.batch(Cmd.message(message), cmd))

    case let .Stash(stash):
        let gitCmd = model.git.stash.stash(StashConfig())
        let message = Message.Info(.Message("Running \(gitCmd.cmd())"))
        let cmd = Effect(gitCmd.exec()).perform { Message.UserInitiatedGitComandResultShowStatus($0) }
        return (model, Cmd.batch(Cmd.message(message), cmd))
    }
}
