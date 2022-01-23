import Foundation
import Slowbox

public typealias ViewEvent<Message> = (KeyEvent, Message)

public struct Line<Message> {
    
    let content: TextType
    let events: [ViewEvent<Message>]
    
    public init(_ content: TextType, events: [ViewEvent<Message>] = []) {
        self.content = content
        self.events = events
    }
}
