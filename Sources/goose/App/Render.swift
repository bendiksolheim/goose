import Foundation
import Tea

func render(model: Model) -> Node {
    let view = model.views.last!
    let content: Node
    switch view.buffer {
    case let .StatusBuffer(statusModel):
        content = renderStatus(model: statusModel)
    case let .LogBuffer(log):
        content = renderLog(log: log)
    case .GitLogBuffer:
        content = renderGitLog(gitLog: model.gitLog)
    case let .CommitBuffer(commitModel):
        content = renderDiff(diff: commitModel)
    }

    if model.menu.shouldShow() {
        return Vertical(.Fill, .Fill) {
            Vertical(.Fill, .Percentage(50)) {
                content
            }
            renderMenu(model.menu)
        }
    } else {
        return Vertical(.Fill, .Fill) {
            Vertical(.Fill, .Fill, view.cursor) {
                content
            }
            renderInfoLine(info: model.info)
        }
    }
}
