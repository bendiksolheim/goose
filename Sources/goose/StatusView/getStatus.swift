import Bow
import BowEffects
import Foundation
import GitLib
import os.log
import Tea

func getStatus(git: Git) -> Cmd<Message> {
    let branch = Task<LowLevelProcessResult>.var()
    let tracking = Task<LowLevelProcessResult>.var()
    let aheadBehind = Task<LowLevelProcessResult>.var()
    let ahead = Task<[GitCommit]>.var()
    let behind = Task<[GitCommit]>.var()
    let status = Task<LowLevelProcessResult>.var()
    let log = Task<LowLevelProcessResult>.var()
    let worktree = Task<LowLevelProcessResult>.var()
    let index = Task<LowLevelProcessResult>.var()
    let gitConfig = Task<GitConfig>.var()
    let stash = Task<LowLevelProcessResult>.var()

    let result = binding(
            branch <- git.symbolicref().exec(),
            tracking <- git.revparse(branch.get.output).exec(),
            aheadBehind <- git.revlist(branch.get.output).exec(),
            ahead <- getAheadOrBehind(git: git, parseAhead(aheadBehind.get)),
            behind <- getAheadOrBehind(git: git, parseBehind(aheadBehind.get)),
            status <- git.status().exec(),
            stash <- git.stash.list().exec(),
            log <- git.log(num: 10).exec(),
            worktree <- git.diff.files().exec(),
            index <- git.diff.index().exec(),
            gitConfig <- config(git: git),
            yield: statusSuccess(git: git, branch.get, tracking.get, status.get, stash.get, log.get, worktree.get, index.get, ahead.get, behind.get, gitConfig.get)
    )^

    return Effect(result).perform(
            { error in .GitResult([], .GotStatus(.Error(error))) },
            { success in .GitResult(success.gitLog, .GotStatus(success.result)) }
    )
}

func runAndMap<T>(_ task: IO<Error, GitLogAndResult<AsyncData<T>>>, _ mapper: (AsyncData<T>) -> GitResult) -> Message {
    task.unsafeRunSyncEither().fold(
            { error in .GitResult([], mapper(.Error(error))) },
            { success in .GitResult(success.gitLog, mapper(success.result)) }
    )
}

func parseRevlist(_ revlist: LowLevelProcessResult) -> ([String], [String]) {
    let commits = revlist.output.split(regex: "\n")
    let ahead = commits.filter {
                $0.starts(with: "<")
            }
            .map {
                String($0[1...])
            }
    let behind = commits.filter {
                $0.starts(with: ">")
            }
            .map {
                String($0[1...])
            }
    return (ahead, behind)
}

func parseAhead(_ revlist: LowLevelProcessResult) -> [String] {
    revlist.output.split(regex: "\n")
            .filter {
                $0.starts(with: "<")
            }
            .map {
                String($0[1...])
            }
}

func parseBehind(_ revlist: LowLevelProcessResult) -> [String] {
    revlist.output.split(regex: "\n")
            .filter {
                $0.starts(with: ">")
            }
            .map {
                String($0[1...])
            }
}

func getAheadOrBehind(git: Git, _ aheadOrBehind: [String]) -> Task<[GitCommit]> {
    aheadOrBehind.isEmpty
            ? Task.pure([])^
            : git.show.plain(aheadOrBehind).exec().map {
                $0.output
            }
            .map {
                parseCommits(git: git, $0)
            }^
}

func statusSuccess(
        git: Git,
        _ branch: LowLevelProcessResult,
        _ tracking: LowLevelProcessResult,
        _ status: LowLevelProcessResult,
        _ stash: LowLevelProcessResult,
        _ log: LowLevelProcessResult,
        _ worktree: LowLevelProcessResult,
        _ index: LowLevelProcessResult,
        _ ahead: [GitCommit],
        _ behind: [GitCommit],
        _ gitConfig: GitConfig) -> GitLogAndResult<AsyncData<StatusInfo>> {
    let parsedStatus = parseStatus(status.output)
    let parsedStash = parseStash(stash.output)
    let commits = parseCommits(git: git, log.output)
    let parsedWorktree = mapDiff(git: git, diff: worktree)
    let parsedIndex = mapDiff(git: git, diff: index)

    return GitLogAndResult(
            [branch, tracking, status, log, worktree, index].map {
                GitLogEntry($0)
            },
            .Success(StatusInfo(
                    branch: branch.output,
                    upstream: tracking.output,
                    untracked: parsedStatus.changes.filter(isUntracked).map {
                        Untracked($0.file)
                    },
                    unstaged: parsedStatus.changes.filter(isUnstaged).map {
                        Unstaged($0.file, $0.status, parsedWorktree[$0.file] ?? [])
                    },
                    staged: parsedStatus.changes.filter(isStaged).map {
                        Staged($0.file, $0.status, parsedIndex[$0.file] ?? [])
                    },
                    stash: parsedStash,
                    log: commits,
                    ahead: ahead,
                    behind: behind,
                    config: gitConfig

            ))
    )
}

private func mapDiff(git: Git, diff: LowLevelProcessResult) -> [String: [GitHunk]] {
    let files = git.diff.parse(diff.output).files
    return files.reduce(into: [:]) {
        $0[$1.source] = $1.hunks
    }
}

struct GitLogAndResult<T> {
    let gitLog: [GitLogEntry]
    let result: T

    init(_ gitLog: [GitLogEntry], _ result: T) {
        self.gitLog = gitLog
        self.result = result
    }
}

func config(git: Git) -> Task<GitConfig> {
    git.config.all().exec()
            .map {
                git.config.parse($0.output)
            }^
}
