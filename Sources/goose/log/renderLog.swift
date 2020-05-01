import Foundation
import tea

func renderLog(log: AsyncData<LogInfo>) -> [Renderable<Message>] {
    switch log {
    case .loading:
        return [TextLine("Loading...")]
    case .error(let error):
        return [TextLine("Error: \(error.localizedDescription)")]
    case .success(let log):
        return Section(title: TextLine("Commits in \(log.branch)"), items: log.commits.map(commitMapper), open: true)
    }
}

