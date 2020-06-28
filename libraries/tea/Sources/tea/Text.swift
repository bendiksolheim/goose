import Foundation
import Termbox

public protocol TextType {
    var chars: [Char] { get }
    var count: Int { get }

    subscript(_: Int) -> Char { get }
}

public struct Text: TextType {
    public let chars: [Char]
    public var count: Int {
        chars.count
    }

    public init(_ text: String, _ foreground: Color = .Normal, _ background: Color = .Normal) {
        chars = text.map { Char($0, foreground, background) }
    }

    init(_ chars: [Char]) {
        self.chars = chars
    }

    public func with(foreground: Color?,
                     background: Color?) -> Text {
        let newChars = chars.map { $0.with(foreground: foreground ?? $0.foreground, background: background ?? $0.background) }
        return Text(newChars)
    }

    public subscript(n: Int) -> Char {
        chars[n]
    }
}

public struct Char {
    let char: Character
    let foreground: Color
    let background: Color

    public init(_ char: Character, _ foreground: Color = .Normal, _ background: Color = .Normal) {
        self.char = char
        self.foreground = foreground
        self.background = background
    }

    public func with(foreground: Color? = nil,
                     background: Color? = nil) -> Char {
        Char(char, foreground ?? self.foreground, background ?? self.background)
    }

    public func unicodeScalar() -> UnicodeScalar {
        String(char).unicodeScalars.first!
    }
}

extension String: TextType {
    public subscript(n: Int) -> Char {
        Char(self[n], foreground, background)
    }

    public var chars: [Char] {
        map { Char($0) }
    }

    public var foreground: Color {
        .Normal
    }

    public var background: Color {
        .Normal
    }
}

public func + (lhs: String, rhs: Text) -> Text {
    Text(lhs.map { Char($0) } + rhs.chars)
}

public func + (lhs: Text, rhs: String) -> Text {
    Text(lhs.chars + rhs.map { Char($0) })
}

public func + (lhs: Text, rhs: Text) -> Text {
    Text(lhs.chars + rhs.chars)
}
