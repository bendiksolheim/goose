import Foundation
import GitLib

public struct CommitModel: Equatable {
    let hash: String
    let commit: AsyncData<GitCommit>

    func with(hash: String? = nil, commit: AsyncData<GitCommit>? = nil) -> CommitModel {
        CommitModel(hash: hash ?? self.hash, commit: commit ?? self.commit)
    }
}
