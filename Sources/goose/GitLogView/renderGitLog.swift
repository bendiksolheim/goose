import tea

func renderGitLog(gitLog: GitLogModel) -> [Line<Message>] {
    let a: [[Line<Message>]] = gitLog.history.map { entry in
        let id = entry.identifier()
        let events: [ViewEvent<Message>] = [
            (.tab, .UpdateGitLog(id))
        ]
        let code = Text(String(entry.exitCode), entry.success ? .Green : .Red)
        let command = Text(entry.command, .Blue)
        let textView = Line(code + " " + command, events: events)
        let output: [Line<Message>] = entry.result.split(regex: "\n").map { line in
            Line<Message>(line)
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
