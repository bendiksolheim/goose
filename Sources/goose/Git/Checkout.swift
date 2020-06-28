import Foundation
import GitLib

func checkout(files: [String]) -> Message {
    let task = execute(process: ProcessDescription.git(Git.checkout(files: files)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
