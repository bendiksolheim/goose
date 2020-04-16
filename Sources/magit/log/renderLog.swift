import Foundation
import Tea

func renderLog(log: AsyncData<LogInfo>) -> [Line<Message>] {
    switch log {
    case .loading:
        return [Line("Loading...")]
    case .error(let error):
        return [Line("Error: \(error.localizedDescription)")]
    case .success(let log):
        return Section(title: Line("Commits in \(log.branch)"), items: log.commits.map(commitMapper), open: true)
    }
}
