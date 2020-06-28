import Termbox

public enum Color {
    case Normal
    case Black
    case Red
    case Green
    case Yellow
    case Blue
    case Magenta
    case Cyan
    case White
    case Custom(AttrSize)

    var toTermbox: Attributes {
        switch self {
        case .Normal:
            return .default
        case .Black:
            return .black
        case .Red:
            return .red
        case .Green:
            return .green
        case .Yellow:
            return .yellow
        case .Blue:
            return .blue
        case .Magenta:
            return .magenta
        case .Cyan:
            return .cyan
        case .White:
            return .white

        case let .Custom(color):
            guard color >= 0, color < 256 else { return .default }
            return Attributes(rawValue: color)
        }
    }
}
