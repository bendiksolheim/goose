import Foundation
import GitLib

func push() -> Message {
    let task = Git.push().exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }) { _ in Message.CommandSuccess }
}
