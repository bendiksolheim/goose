import Foundation
import Tea

struct Logger {
    static var debug = false
    
    static func log(_ message: String) {
        if debug {
            Tea.debug(message)
        }
    }
}
