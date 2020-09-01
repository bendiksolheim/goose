import tea

func renderGitLog(gitLog: GitLogModel) -> [View<Message>] {
    gitLog.history.map { entry in
        let command = TextView<Message>(Text(entry.command, .Blue))
        let output = entry.result.split(regex: "\n").map { line in
            TextView<Message>(line)
        }
        
        return CollapseView<Message>(content: [command] + output + [EmptyLine()], open: true)
    }
}
