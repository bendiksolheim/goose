import Foundation
import tea

func renderLog(log: AsyncData<LogInfo>) -> [View<Message>] {
    switch log {
    case .Loading:
        return [TextView("Loading...")]

    case let .Error(error):
        return [TextView("Error: \(error.localizedDescription)")]

    case let .Success(log):
        let title = TextView<Message>("Commits in \(log.branch)")
        return [CollapseView(content: [title] + log.commits.map(commitMapper), open: true)]
    }
}
