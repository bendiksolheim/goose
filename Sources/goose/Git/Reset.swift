import Foundation
import GitLib

func resetFile(files: [String]) -> Message {
    let task = Git.reset(files).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
