import Foundation

func commit(_ amend: Bool = false) -> Message {
    let result = amend ? runCommand("git commit --amend -v") : runCommand("git commit -v")
    if result == 0 {
        return Message.commandSuccess
    } else {
        return Message.info(.Message("Error executing vim: \(result)"))
    }
}

func view(file: String) -> Message {
    let result = runCommand("vim \(file)")
    if result == 0 {
        return Message.commandSuccess
    } else {
        return Message.info(.Message("Error opening file: \(result)"))
    }
}
