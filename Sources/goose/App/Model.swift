import Foundation
import tea

enum Views {
    case StatusView
    case LogView
    case CommitView
}

struct CursorModel: Equatable {
    let x: UInt
    let y: UInt

    init(_ x: UInt, _ y: UInt) {
        self.x = x
        self.y = y
    }
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

struct Model: Equatable {
    let views: [Views]
    let status: StatusModel
    let log: AsyncData<LogInfo>
    let commit: CommitModel
    let info: InfoMessage
    let container: ScrollState
    let keyMap: KeyMap

    func copy(withViews views: [Views]? = nil,
              withStatus status: StatusModel? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withCommit commit: CommitModel? = nil,
              withInfo info: InfoMessage? = nil,
              withContainer container: ScrollState? = nil,
              withKeyMap keyMap: KeyMap? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              commit: commit ?? self.commit,
              info: info ?? self.info,
              container: container ?? self.container,
              keyMap: keyMap ?? self.keyMap)
    }

    func pushView(view: Views) -> Model {
        copy(withViews: views + [view])
    }

    func popView() -> Model {
        copy(withViews: views.dropLast())
    }
}

struct KeyMap: Equatable {
    let map: [KeyEvent: (Model) -> (Model, Cmd<Message>)]

    init(_ map: [KeyEvent: (Model) -> (Model, Cmd<Message>)]) {
        self.map = map
    }

    subscript(key: KeyEvent, _: Model) -> (Model) -> (Model, Cmd<Message>) {
        map[key, default: { ($0, Cmd.none()) }]
    }

    static func == (lhs: KeyMap, rhs: KeyMap) -> Bool {
        lhs.map.keys == rhs.map.keys
    }
}
