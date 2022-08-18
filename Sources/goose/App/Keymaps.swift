import Foundation
import Slowbox

struct KeyMap: Equatable, Encodable {
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

    func encode(to encoder: Encoder) throws {
        let stringDictionary = Dictionary(
                uniqueKeysWithValues: map.map { ($0.stringValue(), $1) }
        )
        var container = encoder.singleValueContainer()
        try container.encode(stringDictionary)
    }
}

struct KeyCommand: Equatable, Encodable {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        try container.encode("<message>", forKey: .message)
        try container.encode(visible, forKey: .visible)
    }

    enum CodingKeys: String, CodingKey {
        case command
        case message
        case visible
    }
}

func + (lhs: KeyMap, rhs: KeyMap) -> KeyMap {
    KeyMap(lhs.map.combine(rhs.map))
}

// Action maps

let commandMap = KeyMap([
    .l: KeyCommand("Log", .Action(.KeyMap(logActionsMap))),
    .g: KeyCommand("Refresh current buffer", .Action(.Refresh)),
    .c: KeyCommand("Commit", .Action(.KeyMap(commitActionsMap))),
    .p: KeyCommand("Push", .Action(.KeyMap(pushActionsMap))),
    .F: KeyCommand("Pull", .Action(.KeyMap(pullActionsMap))),
    .dollar: KeyCommand("Git output", .Action(.GitLog), false),
])

let commitActionsMap = KeyMap([
    .c: KeyCommand("Commit", .Action(.Commit)),
    .a: KeyCommand("Amend", .Action(.AmendCommit))
])

let logActionsMap = KeyMap([
    .l: KeyCommand("current", .Action(.Log))
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
