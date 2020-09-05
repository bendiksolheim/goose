import Foundation
import GitLib

func resetFile(git: Git, files: [String]) -> Message {
    let task = git.reset(files).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
