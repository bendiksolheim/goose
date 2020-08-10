import Foundation
import GitLib

func addFile(files: [String]) -> Message {
    let task = Git.add(files).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
