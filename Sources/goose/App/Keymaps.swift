import Foundation

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

let normalMap = KeyMap([
    .q: .Action(.PopView),
    .l: .Action(.Log),
    .g: .Action(.Refresh),
    .c: .Action(.KeyMap(commitMap)),
])

let commitMap = KeyMap([
    .c: .Action(.Commit),
    .a: .Action(.AmendCommit)
])

func queryMap(_ msg: Message) -> KeyMap {
    KeyMap([
        .y: .queryResult(.Perform(msg)),
        .n: .queryResult(.Abort),
        .q: .queryResult(.Abort),
        .esc: .queryResult(.Abort),
    ])
}