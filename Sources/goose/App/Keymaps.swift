import Foundation
import Slowbox

struct KeyMap: Equatable, Encodable {
    let sections: [KeySection]

    init(_ sections: [KeySection]) {
        self.sections = sections
    }

    subscript(key: KeyEvent) -> Message? {
        for section in sections {
            if let event = section[key] {
                return event
            }
        }
        return nil
    }
}

struct KeySection: Equatable, Encodable {
    let title: String
    let map: [KeyEvent: KeyCommand]

    init(_ title: String, _ map: [KeyEvent: KeyCommand]) {
        self.title = title
        self.map = map
    }

    subscript(key: KeyEvent) -> Message? {
        map[key]?.message
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

    static func ==(lhs: KeyCommand, rhs: KeyCommand) -> Bool {
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

func +(lhs: KeyMap, rhs: KeyMap) -> KeyMap {
    KeyMap(lhs.sections + rhs.sections)
}

// Action maps

let commandMap = KeyMap([
    KeySection("Transient commands", [
        .l: KeyCommand("Log", .PushKeyMap(logActionsMap)),
        .g: KeyCommand("Refresh current buffer", .Action(.Refresh)),
        .c: KeyCommand("Commit", .PushKeyMap(commitActionsMap)),
        .p: KeyCommand("Push", .PushKeyMap(pushActionsMap)),
        .F: KeyCommand("Pull", .PushKeyMap(pullActionsMap)),
        .Z: KeyCommand("Stash", .PushKeyMap(stashActionsMap)),
    ])
])

let commitActionsMap = KeyMap([
    KeySection("Create", [
        .c: KeyCommand("Commit", .Action(.Commit))
    ]),
    KeySection("Edit HEAD", [
        .a: KeyCommand("Amend", .Action(.AmendCommit))
    ])
])

let logActionsMap = KeyMap([
    KeySection("Log", [.l: KeyCommand("current", .Action(.Log))])
])

let pushActionsMap = KeyMap([
    KeySection("Push to", [.u: KeyCommand("@{upstream}", .Action(.Push))])
])

let pullActionsMap = KeyMap([
    KeySection("Pull from", [.u: KeyCommand("@{upstrean}", .Action(.Pull))])
])

let stashActionsMap = KeyMap([
    KeySection("Stash", [.z: KeyCommand("both", .GitCommand(.Stash))])
])

// Querying

func queryMap(_ msg: Message) -> KeyMap {
    KeyMap([
        KeySection("?", [
            .y: KeyCommand("Yes", .QueryResult(.Perform(msg)), false),
            .n: KeyCommand("No", .QueryResult(.Abort)),
            .q: KeyCommand("Abort", .QueryResult(.Abort)),
            .esc: KeyCommand("Abort", .QueryResult(.Abort))
        ])
    ])
}
