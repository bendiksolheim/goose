import Foundation
import os.log

func log(_ message: String) {
    os_log("%{public}@", message)
}

func log(_ prefix: String, _ message: String) {
    os_log("%{public}@: %{public}@", prefix, message)
}
