import Bow
import BowEffects
import Foundation
import GitLib
import Tea

public struct LogInfo: Equatable, Encodable {
    let branch: String
    let commits: [GitLogLine]
}

func getLog(git: Git) -> Cmd<Message> {
    let ref = Task<LowLevelProcessResult>.var()
    let log = Task<LowLevelProcessResult>.var()
    let result = binding(
        ref <- git.symbolicref().exec(),
        log <- git.log.log(config: GitLogConfig(graph: true, num: 100)).exec(),
        yield: logSuccess(git: git, branch: ref.get, log: log.get)
    )^

    return Effect(result).perform(
            { error in .GitResult([], .GotLog(.Error(error)))},
            { success in .GitResult(success.gitLog, .GotLog(success.result))}
    )
}

func logSuccess(git: Git, branch: LowLevelProcessResult, log: LowLevelProcessResult) -> GitLogAndResult<AsyncData<LogInfo>> {
    GitLogAndResult(
        [branch, log].map { GitLogEntry($0) },
        .Success(LogInfo(branch: branch.output, commits: parseLog(git: git, log.output)))
    )
}
