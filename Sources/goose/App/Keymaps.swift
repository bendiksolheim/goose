import Foundation
import TermSwift

struct KeyMap: Equatable {
    let map: [KeyEvent: KeyCommand]

    init(_ map: [KeyEvent: KeyCommand]) {
        self.map = map
    }

    subscript(key: KeyEvent) -> Message? {
        map[key]?.message
    }

    static func == (lhs: KeyMap, rhs: KeyMap) -> Bool {
        lhs.map.keys == rhs.map.keys
    }
}

struct KeyCommand: Equatable {
    let command: String
    let message: Message
    let visible: Bool
    
    init(_ command: String, _ message: Message, _ visible: Bool = true) {
        self.command = command
        self.message = message
        self.visible = visible
    }
    
    static func == (lhs: KeyCommand, rhs: KeyCommand) -> Bool {
        lhs.command == rhs.command
    }
}

func + (lhs: KeyMap, rhs: KeyMap) -> KeyMap {
    KeyMap(lhs.map.combine(rhs.map))
}

// View maps

let statusMap = KeyMap([
    .q: KeyCommand("Back", .DropBuffer)
]) + actionsMap

let logMap = KeyMap([
    .q: KeyCommand("Back", .DropBuffer)
]) + actionsMap

let commitMap = KeyMap([
    .q: KeyCommand("Back", .DropBuffer)
]) + actionsMap

// Action maps

let actionsMap = KeyMap([
    .l: KeyCommand("Log", .Action(.Log)),
    .g: KeyCommand("Refresh current buffer", .Action(.Refresh)),
    .c: KeyCommand("Commit", .Action(.KeyMap(commitActionsMap))),
    .p: KeyCommand("Push", .Action(.KeyMap(pushActionsMap))),
    .F: KeyCommand("Pull", .Action(.KeyMap(pullActionsMap))),
    .dollar: KeyCommand("Git output", .Action(.GitLog), false),
    .question: KeyCommand("Show help", .Action(.ToggleKeyMap(true)), false),
    .esc: KeyCommand("Hide help", .Action(.ToggleKeyMap(false)), false)
])

let commitActionsMap = KeyMap([
    .c: KeyCommand("Commit", .Action(.Commit)),
    .a: KeyCommand("Amend", .Action(.AmendCommit))
])

let pushActionsMap = KeyMap([
    .u: KeyCommand("@{upstream}", .Action(.Push))
])

let pullActionsMap = KeyMap([
    .u: KeyCommand("@{upstrean}", .Action(.Pull))
])

// Querying

func queryMap(_ msg: Message) -> KeyMap {
    KeyMap([
        .y: KeyCommand("Yes", .QueryResult(.Perform(msg)), false),
        .n: KeyCommand("No", .QueryResult(.Abort)),
        .q: KeyCommand("Abort", .QueryResult(.Abort)),
        .esc: KeyCommand("Abort", .QueryResult(.Abort))
    ])
}
