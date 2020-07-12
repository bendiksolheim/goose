import Foundation
import GitLib

func apply(patch: String, reverse: Bool = false, cached: Bool = false) -> Message {
    let task = execute(process: ProcessDescription.git(Git.apply(reverse: reverse, cached: cached)), input: patch)
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
