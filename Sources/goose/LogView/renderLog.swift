import Foundation
import Tea

func renderLog(log: AsyncData<LogInfo>) -> [Content<Message>] {
    switch log {
    case .Loading:
        return [Content("Loading...")]

    case let .Error(error):
        return [Content("Error: \(error.localizedDescription)")]

    case let .Success(log):
        let title = Content<Message>("Commits in \(log.branch)")
        return [title] + log.commits.map(commitMapper)
    }
}
