import Foundation
import os.log

struct Logger {
    static var debug = false
    
    static func log(_ message: String) {
        if debug {
            os_log("%{public}@", message)
        }
    }

    static func log(_ prefix: String, _ message: String) {
        if debug {
            os_log("%{public}@: %{public}@", prefix, message)
        }
    }
}
