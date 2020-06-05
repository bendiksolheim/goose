import Foundation
import tea

enum Views {
    case status
    case log
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
    case Info(String)
    case Query(String, Message)
    
    
    static func == (lhs: InfoMessage, rhs: InfoMessage) -> Bool {
        switch (lhs, rhs) {
        case (.None, .None):
            return true
        case (.Info(let lhsInfo), .Info(let rhsInfo)):
            return lhsInfo == rhsInfo
        case (.Query(let lhsQuery, _), .Query(let rhsQuery, _)):
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
    let info: InfoMessage
    let container: ScrollState
    let keyMap: KeyMap
    
    func copy(withViews views: [Views]? = nil,
              withStatus status: StatusModel? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withInfo info: InfoMessage? = nil,
              withContainer container: ScrollState? = nil,
              withKeyMap keyMap: KeyMap? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              info: info ?? self.info,
              container: container ?? self.container,
              keyMap: keyMap ?? self.keyMap
        )
    }
    
    func pushView(view: Views) -> Model {
        copy(withViews: self.views + [view])
    }
    
    func popView() -> Model {
        copy(withViews: self.views.dropLast())
    }
}

struct KeyMap: Equatable {
    let map: [KeyEvent : (Model) -> (Model, Cmd<Message>)]
    
    init(_ map: [KeyEvent : (Model) -> (Model, Cmd<Message>)]) {
        self.map = map
    }
    
    subscript(key: KeyEvent, model: Model) -> (Model) -> (Model, Cmd<Message>) {
        get {
            map[key, default: { ($0, Cmd.none()) }]
        }
    }
    
    static func == (lhs: KeyMap, rhs: KeyMap) -> Bool {
        lhs.map.keys == rhs.map.keys
    }
}
