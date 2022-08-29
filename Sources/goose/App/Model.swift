import Foundation
import GitLib
import Tea
import Slowbox

struct Model: Equatable, Encodable {
    let git: Git
    let views: [View]
    let info: InfoMessage
    let menu: Menu
    let gitLog: GitLogModel

    func with(buffer: [View]? = nil,
              info: InfoMessage? = nil,
              menu: Menu? = nil,
              gitLog: GitLogModel? = nil) -> Model {
        Model(git: git,
              views: buffer ?? self.views,
              info: info ?? self.info,
              menu: menu ?? self.menu,
              gitLog: gitLog ?? self.gitLog)
    }
    
    func navigate(to newView: View) -> Model {
        with(buffer: views + [newView], menu: Menu.empty())
    }
    
    func navigate(to newBuffer: Buffer) -> Model {
        with(buffer: views + [View(buffer: newBuffer)], menu: Menu.empty())
    }
    
    func replace(buffer newView: View) -> Model {
        with(buffer: views.dropLast() + [newView])
    }
    
    func replace(buffer newBuffer: Buffer) -> Model {
        let last = views.last!
        return with(buffer: views.dropLast() + [last.with(buffer: newBuffer)])
    }
    
    func back() -> Model {
        with(buffer: views.dropLast(), menu: Menu.empty())
    }

}

struct Menu: Equatable, Encodable {
    let keyMaps: [KeyMap]

    static func empty() -> Menu {
        Self(keyMaps: [])
    }

    func push(keyMap: KeyMap) -> Menu {
        Self(keyMaps: keyMaps + [keyMap])
    }

    func pop() -> Menu {
        Self(keyMaps: keyMaps.dropLast(1))
    }

    func shouldShow() -> Bool {
        keyMaps.count > 0
    }

    func active() -> KeyMap? {
        keyMaps.last
    }

    subscript(event: KeyEvent) -> Message? {
        (keyMaps.last ?? commandMap)[event]
    }
}

struct View: Equatable, Encodable {
    let buffer: Buffer
    let cursor: Cursor

    init(buffer: Buffer) {
        self.buffer = buffer
        cursor = Cursor.initial()
    }

    private init(buffer: Buffer, cursor: Cursor) {
        self.buffer = buffer
        self.cursor = cursor
    }

    func with(buffer: Buffer? = nil, cursor: Cursor? = nil) -> View {
        Self(buffer: buffer ?? self.buffer, cursor: cursor ?? self.cursor)
    }
}

enum Buffer: Equatable, Encodable {
    case StatusBuffer(StatusModel)
    case LogBuffer(AsyncData<LogInfo>)
    case GitLogBuffer
    case CommitBuffer(DiffModel)
}

enum InfoMessage: Equatable, Encodable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .None:
            try container.encode("None")
        case let .Message(m):
            try container.encode("Message(\(m))")
        case let .Query(m, _):
            try container.encode("Query(\(m), _)")
        }
    }
}
