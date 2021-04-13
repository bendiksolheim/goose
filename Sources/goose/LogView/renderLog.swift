import Foundation
import tea

func renderLog(log: AsyncData<LogInfo>) -> [Line<Message>] {
    switch log {
    case .Loading:
        return [Line("Loading...")]

    case let .Error(error):
        return [Line("Error: \(error.localizedDescription)")]

    case let .Success(log):
        let title = Line<Message>("Commits in \(log.branch)")
        return [title] + log.commits.map(commitMapper)
    }
}
