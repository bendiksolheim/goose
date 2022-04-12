import Foundation
import Tea
import Slowbox

func renderInfoLine(info: InfoMessage) -> Content<Message> {
    switch info {
    case .None:
        return Content<Message>("Press ? for help")

    case let .Message(message):
        return Content(message)

    case let .Query(message, _):
        return Content(Text(message, .Blue, .Default))
    }
}
