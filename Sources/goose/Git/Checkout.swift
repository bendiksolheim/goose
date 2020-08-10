import Foundation
import GitLib

func checkout(files: [String]) -> Message {
    let task = Git.checkout(files: files).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
