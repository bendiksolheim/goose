import Foundation
import tea

func renderLog(log: AsyncData<LogInfo>) -> [View<Message>] {
    switch log {
    case .loading:
        return [TextView("Loading...")]
    case .error(let error):
        return [TextView("Error: \(error.localizedDescription)")]
    case .success(let log):
        let title = TextView<Message>("Commits in \(log.branch)")
        return [CollapseView(content: [title] + log.commits.map(commitMapper), open: true)]
    }
}

