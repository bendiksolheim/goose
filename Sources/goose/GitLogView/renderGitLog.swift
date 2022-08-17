import Tea

func renderGitLog(gitLog: GitLogModel) -> Node {
    let a: [Node] = gitLog.history.map { entry in
        let id = entry.identifier()
        let code = FormattedText(String(entry.exitCode), entry.success ? .Green : .Red)
        let command = FormattedText(entry.command, .Blue)
        let textView = Text(code + " " + command, [(.tab, Message.UpdateGitLog(id))])
        let output = entry.result.split(regex: "\n").map { line in
            Text(line)
        } + [EmptyLine()]
        
        let open = gitLog.visibility[id, default: false]

        return Vertical(.Fill, .Auto) {
            [textView]
            if open {
                output
            }
        }
    }.flatMap { $0 }

    return Vertical(.Fill, .Fill) {
        a
    }
}
