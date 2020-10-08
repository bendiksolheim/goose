import tea

func renderGitLog(gitLog: GitLogModel) -> [View<Message>] {
    gitLog.history.map { entry in
        let id = entry.identifier()
        let events: [ViewEvent<Message>] = [
            (.tab, .UpdateGitLog(id))
        ]
        let code = Text(String(entry.exitCode), entry.success ? .Green : .Red)
        let command = Text(entry.command, .Blue)
        let textView = TextView(code + " " + command, events: events)
        let output = entry.result.split(regex: "\n").map { line in
            TextView<Message>(line)
        }
        
        let open = gitLog.visibility[id, default: false]
        
        return CollapseView<Message>(content: [textView] + output + [EmptyLine()], open: open)
    }
}
