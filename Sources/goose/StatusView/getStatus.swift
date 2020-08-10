import Bow
import BowEffects
import Foundation
import GitLib

public enum AsyncData<T: Equatable>: Equatable {
    case Loading
    case Success(T)
    case Error(Error)

    public static func == (lhs: AsyncData<T>, rhs: AsyncData<T>) -> Bool {
        switch (lhs, rhs) {
        case (.Loading, .Loading):
            return true

        case let (.Success(l), .Success(r)):
            return l == r

        case let (.Error(l), .Error(r)):
            return l.localizedDescription == r.localizedDescription

        default:
            return false
        }
    }
}

extension GitCommand {
    func exec(_ input: String? = nil) -> Task<ProcessResult> {
        execute(process: ProcessDescription.git(self), input: input)
    }
}

func getStatus() -> Message {
    let branch = Task<String>.var()
    let tracking = Task<String>.var()
    let aheadBehind = Task<([String], [String])>.var()
    let ahead = Task<[GitCommit]>.var()
    let behind = Task<[GitCommit]>.var()
    let status = Task<GitStatus>.var()
    let log = Task<[GitCommit]>.var()
    let worktree = Task<[String: [GitHunk]]>.var()
    let index = Task<[String: [GitHunk]]>.var()
    let gitConfig = Task<GitConfig>.var()

    let result = binding(
        branch <- Git.symbolicref().exec().map { $0.output },
        tracking <- Git.revparse(branch.get).exec().map { $0.output },
        aheadBehind <- Git.revlist(branch.get).exec().map(parseRevlist),
        ahead <- getAheadOrBehind(aheadBehind.get.0),
        behind <- getAheadOrBehind(aheadBehind.get.1),
        status <- Git.status().exec().flatMap(mapStatus),
        log <- Git.log(num: 10).exec().map { $0.output }.map(parseCommits),
        worktree <- Git.diff.files().exec().map(mapDiff),
        index <- Git.diff.index().exec().map(mapDiff),
        gitConfig <- config(),
        yield: statusSuccess(branch.get, tracking.get, status.get, log.get, worktree.get, index.get, ahead.get, behind.get, gitConfig.get)
    )^

    return .GotStatus(result.unsafeRunSyncEither().fold(error, identity))
}

func parseRevlist(_ revlist: ProcessResult) -> ([String], [String]) {
    let commits = revlist.output.split(regex: "\n")
    let ahead = commits.filter { $0.starts(with: "<") }.map { String($0[1...]) }
    let behind = commits.filter { $0.starts(with: ">") }.map { String($0[1...]) }
    return (ahead, behind)
}

func getAheadOrBehind(_ aheadOrBehind: [String]) -> Task<[GitCommit]> {
    aheadOrBehind.isEmpty
        ? Task.pure([])^
        : Git.show.plain(aheadOrBehind).exec().map { $0.output }.map(parseCommits)^
}

func error<T>(error: Error) -> AsyncData<T> {
    .Error(error)
}

func statusSuccess(_ branch: String, _ tracking: String, _ status: GitStatus, _ commits: [GitCommit], _ worktree: [String: [GitHunk]], _ index: [String: [GitHunk]], _ ahead: [GitCommit], _ behind: [GitCommit], _ gitConfig: GitConfig) -> AsyncData<StatusInfo> {
    return .Success(StatusInfo(
        branch: branch,
        upstream: tracking,
        untracked: status.changes.filter(isUntracked).map { Untracked($0.file) },
        unstaged: status.changes.filter(isUnstaged).map { Unstaged($0.file, $0.status, worktree[$0.file] ?? []) },
        staged: status.changes.filter(isStaged).map { Staged($0.file, $0.status, index[$0.file] ?? []) },
        log: commits,
        ahead: ahead,
        behind: behind,
        config: gitConfig
    ))
}

private func mapStatus(status: ProcessResult) -> IO<Error, GitStatus> {
    parseStatus(status.output)
        .fold(IO.raiseError, IO.pure)^
}

private func mapDiff(diff: ProcessResult) -> [String: [GitHunk]] {
    let files = Git.diff.parse(diff.output).files
    return files.reduce(into: [:]) { $0[$1.source] = $1.hunks }
}
