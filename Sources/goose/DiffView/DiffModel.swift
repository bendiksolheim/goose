import Foundation
import GitLib

public struct DiffModel: Equatable, Encodable {
    let hash: String
    let commit: AsyncData<CommitInfo>

    func with(hash: String? = nil, commit: AsyncData<CommitInfo>? = nil) -> DiffModel {
        DiffModel(hash: hash ?? self.hash, commit: commit ?? self.commit)
    }
}

public struct CommitInfo: Equatable, Encodable {
    let commit: GitCommit
    let stats: Stats
}
