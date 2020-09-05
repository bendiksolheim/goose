import Foundation
import GitLib

func apply(git: Git, patch: String, reverse: Bool = false, cached: Bool = false) -> Message {
    let task = git.apply(reverse: reverse, cached: cached).exec(patch)
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
