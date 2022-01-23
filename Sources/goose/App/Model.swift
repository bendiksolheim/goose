import Foundation
import GitLib
import tea
import Slowbox

struct Model: Equatable {
    let git: Git
    let views: [View]
    let info: InfoMessage
    let renderKeyMap: Bool
    let keyMap: KeyMap
    let gitLog: GitLogModel
    let terminal: TerminalModel

    func with(buffer: [View]? = nil,
              info: InfoMessage? = nil,
              renderKeyMap: Bool? = nil,
              keyMap: KeyMap? = nil,
              gitLog: GitLogModel? = nil,
              terminal: TerminalModel? = nil) -> Model {
        Model(git: git,
              views: buffer ?? self.views,
              info: info ?? self.info,
              renderKeyMap: renderKeyMap ?? self.renderKeyMap,
              keyMap: keyMap ?? self.keyMap,
              gitLog: gitLog ?? self.gitLog,
              terminal: terminal ?? self.terminal)
    }
    
    func navigate(to newView: View) -> Model {
        with(buffer: views + [newView])
    }
    
    func navigate(to newBuffer: Buffer) -> Model {
        with(buffer: views + [View(buffer: newBuffer, viewModel: UIModel(scroll: 0))])
    }
    
    func replace(buffer newView: View) -> Model {
        with(buffer: views.dropLast() + [newView])
    }
    
    func replace(buffer newBuffer: Buffer) -> Model {
        let last = views.last!
        return with(buffer: views.dropLast() + [last.with(buffer: newBuffer)])
    }
    
    func back() -> Model {
        with(buffer: views.dropLast())
    }
}

struct TerminalModel: Equatable {
    let cursor: Cursor
    let size: Size
    
    func with(cursor: Cursor? = nil,
              size: Size? = nil) -> TerminalModel {
        TerminalModel(cursor: cursor ?? self.cursor,
                      size: size ?? self.size)
    }
    
    // This model should never trigger rerender, so we cheat a bit and say instances are always equal
    static func == (lhs: Self, rhs: Self) -> Bool {
        return true
    }
}

struct View: Equatable {
    let buffer: Buffer
    let viewModel: UIModel
    
    func with(buffer: Buffer? = nil,
              viewModel: UIModel? = nil) -> View {
        View(buffer: buffer ?? self.buffer,
             viewModel: viewModel ?? self.viewModel)
    }
}

enum Buffer: Equatable {
    case StatusBuffer(StatusModel)
    case LogBuffer(AsyncData<LogInfo>)
    case GitLogBuffer
    case CommitBuffer(DiffModel)
}

struct UIModel: Equatable {
    let scroll: Int
}

enum InfoMessage: Equatable {
    case None
    case Message(String)
    case Query(String, Message)

    static func == (lhs: InfoMessage, rhs: InfoMessage) -> Bool {
        switch (lhs, rhs) {
        case (.None, .None):
            return true
        case let (.Message(lhsInfo), .Message(rhsInfo)):
            return lhsInfo == rhsInfo
        case let (.Query(lhsQuery, _), .Query(rhsQuery, _)):
            return lhsQuery == rhsQuery
        default:
            return false
        }
    }
}

struct ViewData: Equatable {
    let size: Size
}
