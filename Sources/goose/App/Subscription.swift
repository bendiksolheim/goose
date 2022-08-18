import Foundation
import Tea

let subscriptions: [Sub<Message>] = [
    .Keyboard { event in
        .TerminalEvent(.Keyboard(event))
    },
    .Cursor { event in
        .TerminalEvent(.Cursor(event))
    }
]
