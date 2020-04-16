import Foundation

public func Section<Message>(title: Line<Message>, items: [Line<Message>], open: Bool) -> [Line<Message>] {
    return [title] + ( open ? items + [EmptyLine()] : [EmptyLine()])
}
