import Foundation
import tea

func renderInfoLine(info: InfoMessage) -> TextView<Message> {
    switch info {
    case .None:
        return TextView("")

    case let .Message(message):
        return TextView(message)

    case let .Query(message, _):
        return TextView(Text(message, .Blue, .Normal))
    }
}
