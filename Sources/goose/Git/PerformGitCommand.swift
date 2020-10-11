import GitLib
import tea
import Bow

func performGitCommand(_ cmd: GitCommand, _ showStatus: Bool) -> Cmd<Message> {
    let task = cmd.exec()
    let msg = Cmd.message(Message.Info(.Message("Running \(cmd.cmd())")))
    let resultTask = Task { () -> Message in
        let t = task.unsafeRunSyncEither()
        return .UserInitiatedGitCommandResult(t, showStatus)
    }
    return Cmd.batch(msg, resultTask.perform())
}

func getResultMessage(_ processResult: ProcessResult) -> String {
    if processResult.exitCode == 0 {
        return "Git finished"
    } else {
        let output = processResult.output.split(regex: "\n").last ?? ""
        return "\(output) ... [Hit $ to see git output for details]"
    }
}
