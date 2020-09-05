import Foundation
import GitLib

func restore(git: Git, _ files: [String], _ staged: Bool) -> Message {
    let task = git.restore(files, staged: staged).exec()
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
