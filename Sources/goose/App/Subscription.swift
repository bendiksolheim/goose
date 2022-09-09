import Foundation
import Tea

let subscriptions: [Sub<Message>] = [
    Keyboard.onKeyPress { .TerminalEvent(.Keyboard($0)) },
    Cursor.onMove { .TerminalEvent(.Cursor($0))}
]
