import Foundation
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
            guard color >= 0 && color < 256 else { return .default }
            return Attributes(rawValue: color)
        }
    }
}

public enum Attr {
    case underline
    case reverse
    case bold
    case foreground(Color)
    case background(Color)

    var toTermbox: Attributes {
        switch self {
        case .underline: return .underline
        case .reverse: return .reverse
        case .bold: return .bold
        case let .foreground(color): return color.toTermbox
        case let .background(color): return color.toTermbox
        }
    }
}

public protocol AttrCharType {
    var char: String? { get }
    var attrs: [Attr] { get }
}

public protocol TextType {
    var chars: [AttrCharType] { get }
}

public struct AttrChar: AttrCharType {
    public var char: String?
    public var attrs: [Attr]

    public init(_ char: String?, _ attrs: [Attr] = []) {
        self.char = char
        self.attrs = attrs
    }

    public init(_ attrs: [Attr]) {
        self.char = nil
        self.attrs = attrs
    }

    public init(_ char: Character, _ attrs: [Attr] = []) {
        self.char = String(char)
        self.attrs = attrs
    }
}

extension AttrChar: TextType {
    public var chars: [AttrCharType] {
        [self]
    }
}

public struct AttrText: TextType {
    public private(set) var chars: [AttrCharType]

    public init(_ content: [TextType]) {
        self.chars = content.flatMap { $0.chars }
    }

    public init(_ text: TextType) {
        self.chars = text.chars
    }

    public init(_ chars: [AttrCharType] = []) {
        self.chars = chars
    }

    public mutating func append(_ text: TextType) {
        self.chars += text.chars
    }
}

public struct Text: TextType {
    public let text: String
    public let attrs: [Attr]

    public var chars: [AttrCharType] {
        text.map { AttrChar($0, attrs) }
    }

    var description: String {
        text
    }

    public init(_ text: String, _ attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: AttrCharType {
    public var char: String? { self }
    public var attrs: [Attr] { [] }
}

extension String: TextType {
    public var chars: [AttrCharType] {
        let text = self.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
            of: "\r",
            with: "\n"
        )
        return Array(text)
    }
}

extension Character: AttrCharType {
    public var char: String? { String(self) }
    public var attrs: [Attr] { [] }
}

public func + (lhs: AttrText, rhs: TextType) -> AttrText {
    AttrText(lhs.chars + rhs.chars)
}

public func + (lhs: AttrText, rhs: AttrText) -> AttrText {
    AttrText(lhs.chars + rhs.chars)
}

public func + (lhs: TextType, rhs: TextType) -> TextType {
    AttrText(lhs.chars + rhs.chars)
}
