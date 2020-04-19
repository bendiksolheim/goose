import Foundation

public typealias LineEventHandler<Message> = (KeyEvent, () -> Message)

public struct Line<Message> {
    let chars: [AttrCharType]
    let events: [LineEventHandler<Message>]
    
    public init(_ text: TextType, _ events: [LineEventHandler<Message>] = []) {
        let chars = text.chars
        self.chars = chars
        self.events = events
    }
}

public func EmptyLine<Message>() -> Line<Message> {
    Line(" ")
}
