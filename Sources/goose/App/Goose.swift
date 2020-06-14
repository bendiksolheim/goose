import Foundation
import GitLib
import tea
import os.log

indirect enum Message {
    case gotStatus(AsyncData<StatusInfo>)
    case gotLog(AsyncData<LogInfo>)
    case getCommit(String)
    case gotCommit(AsyncData<GitCommit>)
    case keyboard(KeyEvent)
    case gitCommand(GitCmd)
    case updateVisibility([String : Bool])
    case commandSuccess
    case info(InfoMessage)
    case clearInfo
    case queryResult(QueryResult)
    case ViewFile(String)
    case container(ScrollMessage)
}

enum GitCmd {
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

func initialize() -> (Model, Cmd<Message>) {
    let statusModel = StatusModel(info: .loading, visibility: [:])
    let commitModel = CommitModel(hash: "", commit: .loading)
    return (Model(views: [.StatusView],
                  status: statusModel,
                  log: .loading,
                  commit: commitModel,
                  info: .None,
                  container: ScrollView<Message>.initialState(),
                  keyMap: normalMap),
            Task { getStatus() }.perform())
}


func render(model: Model) -> Window<Message> {
    let view = model.views.last!
    let content: [View<Message>]
    switch view {
    case .StatusView:
        content = renderStatus(model: model.status)
    case .LogView:
        content = renderLog(log: model.log)
    case .CommitView:
        content = renderCommit(commit: model.commit)
    }
    
    return Window(content:
        [ScrollView(content, layoutPolicy: LayoutPolicy(width: .Flexible, height: .Flexible), model.container), renderInfoLine(info: model.info)]
    )
}

func update(message: Message, model: Model) -> (Model, Cmd<Message>) {
    switch message {
    case .gotStatus(let newStatus):
        return (model.copy(withStatus: StatusModel(info: newStatus, visibility: model.status.visibility)), Cmd.none())
        
    case .gotLog(let log):
        return (model.copy(withLog: log), Cmd.none())
        
    case .getCommit(let ref):
        return (model.copy(withCommit: model.commit.with(hash: ref, commit: .loading)).pushView(view: .CommitView), Task { getCommit(ref) }.perform { .gotCommit($0) })
        
    case .gotCommit(let commit):
        return (model.copy(withCommit: model.commit.with(commit: commit)), Cmd.none())
        
    case .keyboard(let event):
        return model.keyMap[event, model](model)
        
    case .gitCommand(let command):
        return performCommand(model, command)
        
    case .updateVisibility(let visibility):
        return (model.copy(withStatus: model.status.with(visibility: visibility)), Cmd.none())
        
    case .commandSuccess:
        return (model, Task { getStatus() }.perform())
        
    case .info(let info):
        switch info {
        case .Message(_):
            return (model.copy(withInfo: info), TProcess.sleep(5.0).perform { Message.clearInfo })
        case .Query(_, let cmd):
            return (model.copy(withInfo: info, withKeyMap: queryMap(cmd)), Cmd.none())
        default:
            return (model.copy(withInfo: info), Cmd.none())
        }
        
    case .clearInfo:
        return (model.copy(withInfo: .None), Cmd.none())
        
    case .queryResult(let queryResult):
        switch queryResult {
        case .Abort:
            return (model.copy(withInfo: .None, withKeyMap: normalMap), Cmd.none())
        case .Perform(let msg):
            return (model.copy(withInfo: .None, withKeyMap: normalMap), Cmd.message(msg))
        }
        
    case .ViewFile(let file):
         return (model, TProcess.spawn { view(file: file) }.perform { $0 })

    case .container(let containerMsg):
        return (model.copy(withContainer: ScrollView<Message>.update(containerMsg, model.container)), Cmd.none())
    }
}

func performCommand(_ model: Model, _ gitCommand: GitCmd) -> (Model, Cmd<Message>) {
    switch gitCommand {
    case .Stage(let selection):
        switch selection {
        case .Section(let files, let status):
            return (model, stage(files, status))
        case .File(let file, let status):
            return (model, stage([file], status))
        case .Hunk(let hunk, let status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, Task { apply(patch: hunk, cached: true) }.perform())
            case .Staged:
                return (model, Cmd.message(.info(.Message("Already staged"))))
            }
        }
        
    case .Unstage(let selection):
        switch selection {
        case .Section(let files, let status):
            return (model, unstage(files, status))
        case .File(let file, let status):
            return (model, unstage([file], status))
        case .Hunk(let patch, let status):
            switch status {
            case .Untracked, .Unstaged:
                return (model, Cmd.message(.info(.Message("Already unstaged"))))
            case .Staged:
                return (model, Task { apply(patch: patch, reverse: true, cached: true) }.perform())
            }
        }
        
    case .Discard(let selection):
        switch selection {
        case .Section(let files, let status):
            return (model, discard(files, status))
            
        case .File(let file, let status):
            return (model, discard([file], status))
            
        case .Hunk(let patch, let status):
            switch status {
            case .Untracked:
                return (model, Cmd.none()) // Impossible state, untracked files does not have hunks
            case .Unstaged:
                return (model, Task { apply(patch: patch, reverse: true) }.perform())
            case .Staged:
                return (model, Task { apply(patch: patch, reverse: true, cached: true) }.andThen { _ in apply(patch: patch, reverse: true) }.perform())
            }
        }
    }
}

func stage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Task { addFile(files: files) }.perform()
    case .Unstaged:
        return Task { addFile(files: files) }.perform()
    case .Staged:
        return Cmd.message(.info(.Message("Already staged")))
    }
}

func unstage(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Cmd.message(.info(.Message("Already unstaged")))
    case .Unstaged:
        return Cmd.message(.info(.Message("Already unstaged")))
    case .Staged:
        return Task { resetFile(files: files) }.perform()
    }
}

func discard(_ files: [String], _ type: Status) -> Cmd<Message> {
    switch type {
    case .Untracked:
        return Task { remove(files: files) }.perform()
    case .Unstaged:
        return Task { checkout(files: files) }.perform()
    case .Staged:
        return Task { restore(files, true) }.andThen { _ in checkout(files: files) }.perform()
    }
}

let normalMap = KeyMap([
    .q : { $0.views.count > 1 ? ($0.popView(), Cmd.none()) : ($0, TProcess.quit()) },
    .l : { ($0.pushView(view: .LogView), Task { getLog() }.perform()) },
    .g : { ($0, Task { getStatus() }.perform()) },
    .c : { ($0, TProcess.spawn { commit() }.perform()) },
])

func queryMap(_ msg: Message) -> KeyMap {
    return KeyMap([
        .y : { ($0, Cmd.message(.queryResult(.Perform(msg)))) },
        .n : { ($0, Cmd.message(.queryResult(.Abort))) },
        .q : { ($0, Cmd.message(.queryResult(.Abort))) },
        .esc : { ($0, Cmd.message(.queryResult(.Abort))) }
    ])
}

let subscriptions: [Sub<Message>] = [
    cursor { .container($0) },
    keyboard { event in .keyboard(event) }
]
