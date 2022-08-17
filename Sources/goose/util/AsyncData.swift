import Foundation

public enum AsyncData<T: Equatable & Encodable>: Equatable, Encodable {
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
            return true
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .Loading:
            try container.encode("loading", forKey: .type)
            try container.encode("", forKey: .value)
        case let .Success(value):
            try container.encode("success", forKey: .type)
            try container.encode(value, forKey: .value)
        case let .Error(err):
            try container.encode("error", forKey: .type)
            try container.encode(err.localizedDescription, forKey: .value)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
}

func error<T>(error: Error) -> AsyncData<T> {
    .Error(error)
}
