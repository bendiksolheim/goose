import Foundation
import tea

enum Buffer {
    case StatusBuffer
    case LogBuffer
    case CommitBuffer
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
    let status: StatusModel
    let log: AsyncData<LogInfo>
    let commit: CommitModel
    let info: InfoMessage
    let scrollState: ScrollState
    let keyMap: KeyMap

    func with(buffer: Buffer? = nil,
              status: StatusModel? = nil,
              log: AsyncData<LogInfo>? = nil,
              commit: CommitModel? = nil,
              info: InfoMessage? = nil,
              scrollState: ScrollState? = nil,
              keyMap: KeyMap? = nil) -> Model {
        Model(buffer: buffer ?? self.buffer,
              status: status ?? self.status,
              log: log ?? self.log,
              commit: commit ?? self.commit,
              info: info ?? self.info,
              scrollState: scrollState ?? self.scrollState,
              keyMap: keyMap ?? self.keyMap)
    }
}
