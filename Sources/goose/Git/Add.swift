import Foundation
import GitLib

func addFile(git: Git, files: [String]) -> Message {
    let task = git.add(files).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
