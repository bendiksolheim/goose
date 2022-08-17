import Foundation
import Tea
import Slowbox

func renderInfoLine(info: InfoMessage) -> Node {
    switch info {
    case .None:
        return Text("Press ? for help")

    case let .Message(message):
        return Text(message)

    case let .Query(message, _):
        return Text(FormattedText(message, .Blue, .Default))
    }
}
