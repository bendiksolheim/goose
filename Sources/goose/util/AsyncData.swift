import Foundation
import os.log

public enum AsyncData<T: Equatable>: Equatable {
    case Loading
    case Success(T)
    case Error(Error)

    public static func == (lhs: AsyncData<T>, rhs: AsyncData<T>) -> Bool {
        os_log("lhs: (%{public}@), rhs: (%{public}@)", "\(lhs)", "\(rhs)")
        switch (lhs, rhs) {
        case (.Loading, .Loading):
            os_log("loading")
            return true

        case let (.Success(l), .Success(r)):
            os_log("success")
            return l == r

        case let (.Error(l), .Error(r)):
            os_log("error")
            return l.localizedDescription == r.localizedDescription

        default:
            os_log("different")
            return true
        }
    }
}

func error<T>(error: Error) -> AsyncData<T> {
    .Error(error)
}
