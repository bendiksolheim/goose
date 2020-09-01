import Bow
import BowEffects
import Foundation
import GitLib

func getStatus() -> Message {
    let branch = Task<ProcessResult>.var()
    let tracking = Task<ProcessResult>.var()
    let aheadBehind = Task<ProcessResult>.var()
    let ahead = Task<[GitCommit]>.var()
    let behind = Task<[GitCommit]>.var()
    let status = Task<ProcessResult>.var()
    let log = Task<ProcessResult>.var()
    let worktree = Task<ProcessResult>.var()
    let index = Task<ProcessResult>.var()
    let gitConfig = Task<GitConfig>.var()

    let result = binding(
        branch <- Git.symbolicref().exec(),
        tracking <- Git.revparse(branch.get.output).exec(),
        aheadBehind <- Git.revlist(branch.get.output).exec(),
        ahead <- getAheadOrBehind(parseAhead(aheadBehind.get)),
        behind <- getAheadOrBehind(parseBehind(aheadBehind.get)),
        status <- Git.status().exec(),
        log <- Git.log(num: 10).exec(),
        worktree <- Git.diff.files().exec(),
        index <- Git.diff.index().exec(),
        gitConfig <- config(),
        yield: statusSuccess(branch.get, tracking.get, status.get, log.get, worktree.get, index.get, ahead.get, behind.get, gitConfig.get)
    )^

    return runAndMap(result) { .GotStatus($0) }
}

func runAndMap<T>(_ task: IO<Error, GitLogAndResult<AsyncData<T>>>, _ mapper: (AsyncData<T>) -> GitResult) -> Message {
    task.unsafeRunSyncEither().fold(
        { error in .GitResult([], mapper(.Error(error))) },
        { success in .GitResult(success.gitLog, mapper(success.result)) }
    )
}

func parseRevlist(_ revlist: ProcessResult) -> ([String], [String]) {
    let commits = revlist.output.split(regex: "\n")
    let ahead = commits.filter { $0.starts(with: "<") }.map { String($0[1...]) }
    let behind = commits.filter { $0.starts(with: ">") }.map { String($0[1...]) }
    return (ahead, behind)
}

func parseAhead(_ revlist: ProcessResult) -> [String] {
    revlist.output.split(regex: "\n")
        .filter { $0.starts(with: "<") }.map { String($0[1...]) }
}

func parseBehind(_ revlist: ProcessResult) -> [String] {
    revlist.output.split(regex: "\n")
        .filter { $0.starts(with: ">") }.map { String($0[1...]) }
}

func getAheadOrBehind(_ aheadOrBehind: [String]) -> Task<[GitCommit]> {
    aheadOrBehind.isEmpty
        ? Task.pure([])^
        : Git.show.plain(aheadOrBehind).exec().map { $0.output }.map(parseCommits)^
}

func statusSuccess(
    _ branch: ProcessResult,
    _ tracking: ProcessResult,
    _ status: ProcessResult,
    _ log: ProcessResult,
    _ worktree: ProcessResult,
    _ index: ProcessResult,
    _ ahead: [GitCommit],
    _ behind: [GitCommit],
    _ gitConfig: GitConfig) -> GitLogAndResult<AsyncData<StatusInfo>> {
    let parsedStatus = parseStatus(status.output)
    let commits = parseCommits(log.output)
    let parsedWorktree = mapDiff(diff: worktree)
    let parsedIndex = mapDiff(diff: index)

    return GitLogAndResult(
        [branch, tracking, status, log, worktree, index].map { GitLogEntry($0) },
        .Success(StatusInfo(
            branch: branch.output,
            upstream: tracking.output,
            untracked: parsedStatus.changes.filter(isUntracked).map { Untracked($0.file) },
            unstaged: parsedStatus.changes.filter(isUnstaged).map { Unstaged($0.file, $0.status, parsedWorktree[$0.file] ?? []) },
            staged: parsedStatus.changes.filter(isStaged).map { Staged($0.file, $0.status, parsedIndex[$0.file] ?? []) },
            log: commits,
            ahead: ahead,
            behind: behind,
            config: gitConfig

        ))
    )
}

private func mapDiff(diff: ProcessResult) -> [String: [GitHunk]] {
    let files = Git.diff.parse(diff.output).files
    return files.reduce(into: [:]) { $0[$1.source] = $1.hunks }
}

struct GitLogAndResult<T> {
    let gitLog: [GitLogEntry]
    let result: T

    init(_ gitLog: [GitLogEntry], _ result: T) {
        self.gitLog = gitLog
        self.result = result
    }
}
