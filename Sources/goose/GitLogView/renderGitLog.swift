import Tea

func renderGitLog(gitLog: GitLogModel) -> [Content<Message>] {
    let a: [[Content<Message>]] = gitLog.history.map { entry in
        let id = entry.identifier()
        let events: [ViewEvent<Message>] = [
            (.tab, .UpdateGitLog(id))
        ]
        let code = Text(String(entry.exitCode), entry.success ? .Green : .Red)
        let command = Text(entry.command, .Blue)
        let textView = Content(code + " " + command, events: events)
        let output: [Content<Message>] = entry.result.split(regex: "\n").map { line in
            Content<Message>(line)
        }
        
        let open = gitLog.visibility[id, default: false]
        
        if open {
            return [textView] + output + [EmptyLine()]
        } else {
            return [textView]
        }
    }
    
    return a.flatMap { $0 }
}
