import Foundation
import Tea

func collapsible(_ header: String, _ events: [ViewEvent<Message>], _ open: Bool, _ content: [Node]) -> [Node] {
    collapsible(FormattedText(header), events, open, content)
}

func collapsible(_ header: FormattedText, _ events: [ViewEvent<Message>], _ open: Bool, _ content: [Node]) -> [Node] {
    let indicator = FormattedText(open ? "▼ " : "▶ ", .DarkGray)
    let header = Text(indicator + header, events)
    return [header] + (open ? content : [])
}