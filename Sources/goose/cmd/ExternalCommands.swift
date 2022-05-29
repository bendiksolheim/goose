import Foundation

enum ProcessResult {
    case Success
    case Failure(String)
}

func commit(amend: Bool = false) -> ProcessResult {
    let result = amend ? runCommand("git commit --amend -v") : runCommand("git commit -v")
    if result == 0 {
        return .Success
    } else {
        return .Failure("Error executing command: \(result)")
    }
}

func view(file: String) -> ProcessResult {
    let result = runCommand("vim \(file)")
    if result == 0 {
        return .Success
    } else {
        return .Failure("Error opening file: \(result)")
    }
}
