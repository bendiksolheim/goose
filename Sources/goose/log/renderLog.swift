import Foundation
import tea

func renderLog(log: AsyncData<LogInfo>) -> [View<Message>] {
    switch log {
    case .loading:
        return [TextView("Loading...")]

    case let .error(error):
        return [TextView("Error: \(error.localizedDescription)")]

    case let .success(log):
        let title = TextView<Message>("Commits in \(log.branch)")
        return [CollapseView(content: [title] + log.commits.map(commitMapper), open: true)]
    }
}
