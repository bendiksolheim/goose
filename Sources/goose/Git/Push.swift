import Foundation
import GitLib

func push(git: Git) -> Message {
    let task = git.push().exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }) { _ in Message.CommandSuccess }
}
