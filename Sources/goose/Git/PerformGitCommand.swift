import GitLib
import Tea
import Bow

//func performGitCommand(_ cmd: GitCommand, _ input: String? = nil) -> Cmd<Message> {
//    return Task { () -> Message in
//        let t = task.unsafeRunSyncEither()
//        return .UserInitiatedGitCommandResult(t, false)
//    }
//    return Task(task).andThen { .UserInitiatedGitCommandResult($0, false)}
//    Effect(cmd.exec(input)).perform(
//            { error in .UserInitiatedGitCommandResult(Either.left(error), false) },
//            { success in .UserInitiatedGitCommandResult(Either.right(success), false) }
//    )
//}

//func performGitCommand(_ cmd: GitCommand, _ input: String? = nil) -> Effect<LowLevelProcessResult> {
//    Effect(Cmd.exec(input))
//}

//func performAndShowGitCommand(_ cmd: GitCommand, _ input: String? = nil) -> (Message, Cmd<Message>) {
//    let task = Effect(cmd.exec(input)).perform(
//            { error in Message.UserInitiatedGitCommandResult(Either.left(error), true) },
//            { success in Message.UserInitiatedGitCommandResult(Either.right(success), false) }
//    )
//    let msg = Message.Info(.Message("Running \(cmd.cmd())"))
//    return (msg, task)
//    let task = cmd.exec(input)
//    let resultTask = Task { () -> Message in
//        let t = task.unsafeRunSyncEither()
//        return .UserInitiatedGitCommandResult(t, true)
//    }
//    let msg = Message.Info(.Message("Running \(cmd.cmd())"))
//    return (msg, resultTask)

//}

func getResultMessage(_ processResult: LowLevelProcessResult) -> String {
    if processResult.exitCode == 0 {
        return "Git finished"
    } else {
        let output = processResult.output.split(regex: "\n").last ?? ""
        return "\(output) ... [Hit $ to see git output for details]"
    }
}
