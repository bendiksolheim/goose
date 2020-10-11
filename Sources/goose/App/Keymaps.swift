import Foundation
import tea

struct KeyMap: Equatable {
    let map: [KeyEvent: Message]

    init(_ map: [KeyEvent: Message]) {
        self.map = map
    }

    subscript(key: KeyEvent) -> Message? {
        map[key]
    }

    static func == (lhs: KeyMap, rhs: KeyMap) -> Bool {
        lhs.map.keys == rhs.map.keys
    }
}

func + (lhs: KeyMap, rhs: KeyMap) -> KeyMap {
    KeyMap(lhs.map.combine(rhs.map))
}

// View maps

let statusMap = KeyMap([
    .q: .DropBuffer
]) + actionsMap

let logMap = KeyMap([
    .q: .DropBuffer
]) + actionsMap

let commitMap = KeyMap([
    .q: .DropBuffer
]) + actionsMap

// Action maps

let actionsMap = KeyMap([
    .l: .Action(.Log),
    .g: .Action(.Refresh),
    .c: .Action(.KeyMap(commitActionsMap)),
    .p: .Action(.KeyMap(pushActionsMap)),
    .F: .Action(.KeyMap(pullActionsMap)),
    .dollar: .Action(.GitLog)
])

let commitActionsMap = KeyMap([
    .c: .Action(.Commit),
    .a: .Action(.AmendCommit)
])

let pushActionsMap = KeyMap([
    .u: .Action(.Push)
])

let pullActionsMap = KeyMap([
    .u: .Action(.Pull)
])

// Querying

func queryMap(_ msg: Message) -> KeyMap {
    KeyMap([
        .y: .QueryResult(.Perform(msg)),
        .n: .QueryResult(.Abort),
        .q: .QueryResult(.Abort),
        .esc: .QueryResult(.Abort)
    ])
}
