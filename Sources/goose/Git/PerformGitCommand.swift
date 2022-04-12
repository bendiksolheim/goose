import GitLib
import Tea
import Bow

func performGitCommand(_ cmd: GitCommand, _ input: String? = nil) -> Task<Message> {
    let task = cmd.exec(input)
    return Task { () -> Message in
        let t = task.unsafeRunSyncEither()
        return .UserInitiatedGitCommandResult(t, false)
    }
}

func performAndShowGitCommand(_ cmd: GitCommand, _ input: String? = nil) -> (Message, Task<Message>) {
    let task = cmd.exec(input)
    let resultTask = Task { () -> Message in
        let t = task.unsafeRunSyncEither()
        return .UserInitiatedGitCommandResult(t, true)
    }
    let msg = Message.Info(.Message("Running \(cmd.cmd())"))
    return (msg, resultTask)
}

func getResultMessage(_ processResult: ProcessResult) -> String {
    if processResult.exitCode == 0 {
        return "Git finished"
    } else {
        let output = processResult.output.split(regex: "\n").last ?? ""
        return "\(output) ... [Hit $ to see git output for details]"
    }
}
