import Foundation
import TermSwift

public typealias ViewEvent<Message> = (KeyEvent, Message)

public struct Line<Message>: CustomStringConvertible {
    
    let content: TextType
    let events: [ViewEvent<Message>]
    
    public init(_ content: TextType, events: [ViewEvent<Message>] = []) {
        self.content = content
        self.events = events
    }
    
    public var description: String {
        return content.terminalRepresentation
    }
}
