import Termbox

public enum Color {
    case normal
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
    case any(AttrSize)

    var toTermbox: Attributes {
        switch self {
        case .normal:
            return .default
        case .black:
            return .black
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .blue:
            return .blue
        case .magenta:
            return .magenta
        case .cyan:
            return .cyan
        case .white:
            return .white

        case let .any(color):
            guard color >= 0, color < 256 else { return .default }
            return Attributes(rawValue: color)
        }
    }
}
