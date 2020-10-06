import tea

func renderGitLog(gitLog: GitLogModel) -> [View<Message>] {
    gitLog.history.map { entry in
        let id = entry.identifier()
        let events: [ViewEvent<Message>] = [
            (.tab, .UpdateGitLog(id))
        ]
        let command = TextView<Message>(Text(entry.command, .Blue), events: events)
        let output = entry.result.split(regex: "\n").map { line in
            TextView<Message>(line)
        }
        
        let open = gitLog.visibility[id, default: false]
        
        return CollapseView<Message>(content: [command] + output + [EmptyLine()], open: open)
    }
}
