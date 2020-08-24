import Foundation
import GitLib

public struct DiffModel: Equatable {
    let hash: String
    let commit: AsyncData<CommitInfo>

    func with(hash: String? = nil, commit: AsyncData<CommitInfo>? = nil) -> DiffModel {
        DiffModel(hash: hash ?? self.hash, commit: commit ?? self.commit)
    }
}

public struct CommitInfo: Equatable {
    let commit: GitCommit
    let stats: Stats
}
