import Foundation
import GitLib

func checkout(git: Git, files: [String]) -> Message {
    let task = git.checkout(files: files).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
