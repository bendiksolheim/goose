import Foundation
import tea

func renderInfoLine(info: InfoMessage) -> TextView<Message> {
    switch info {
    case .None:
        return TextView("")
        
    case .Info(let message):
        return TextView(message)
        
    case .Query(let message, _):
        return TextView(Text(message, .blue, .normal))
    }
}
