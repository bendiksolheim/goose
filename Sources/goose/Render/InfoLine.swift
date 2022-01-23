import Foundation
import tea
import Slowbox

func renderInfoLine(info: InfoMessage) -> Line<Message> {
    switch info {
    case .None:
        return Line("")

    case let .Message(message):
        return Line(message)

    case let .Query(message, _):
        return Line(Text(message, .Blue, .Default))
    }
}
