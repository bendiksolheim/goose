import Foundation
import tea

enum Buffer: Equatable {
    case StatusBuffer(StatusModel)
    case LogBuffer(AsyncData<LogInfo>)
    case CommitBuffer(CommitModel)
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
    let buffer: Buffer
    let info: InfoMessage
    let scrollState: ScrollState
    let keyMap: KeyMap

    func with(buffer: Buffer? = nil,
              info: InfoMessage? = nil,
              scrollState: ScrollState? = nil,
              keyMap: KeyMap? = nil) -> Model {
        Model(buffer: buffer ?? self.buffer,
              info: info ?? self.info,
              scrollState: scrollState ?? self.scrollState,
              keyMap: keyMap ?? self.keyMap)
    }
}
