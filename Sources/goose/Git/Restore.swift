import Foundation
import GitLib

func restore(_ files: [String], _ staged: Bool) -> Message {
    let task = execute(process: ProcessDescription.git(Git.restore(files, staged: staged)))
    let result = task.unsafeRunSyncEither()
    return result.fold({ Message.Info(.Message($0.localizedDescription)) }, { _ in Message.CommandSuccess })
}
