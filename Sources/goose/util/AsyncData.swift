import Foundation

public enum AsyncData<T: Equatable>: Equatable {
    case Loading
    case Success(T)
    case Error(Error)

    public static func == (lhs: AsyncData<T>, rhs: AsyncData<T>) -> Bool {
        switch (lhs, rhs) {
        case (.Loading, .Loading):
            return true

        case let (.Success(l), .Success(r)):
            return l == r

        case let (.Error(l), .Error(r)):
            return l.localizedDescription == r.localizedDescription

        default:
            return false
        }
    }
}

func error<T>(error: Error) -> AsyncData<T> {
    .Error(error)
}
