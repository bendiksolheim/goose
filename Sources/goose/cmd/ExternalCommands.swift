import Foundation

func commit() -> Message {
    let result = runCommand("git commit -v")
    if result == 0 {
        return Message.commandSuccess
    } else {
        return Message.info(.Message("Error executing vim: \(result)"))
    }
}
