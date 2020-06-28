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

/* public enum Attr {
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
 } */
