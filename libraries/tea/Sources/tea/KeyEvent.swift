// NOT IN USE
public enum Key_Event: Hashable {
    case ctrl(CtrlKey_Event)
    case alt(AltKey_Event)
    case shift(ShiftKey_Event)
    case char(CharKey_Event)
    case fn(FnKey_Event)

    // any signals that have common unix meaning are
    // named after that signal
    // (eg C-c int, C-t info, C-z suspend, C-\ quit)
    //
    // the rest are named after ASCII codes from http://www.ascii-code.com
    public static let signalNul: Key_Event = .ctrl(.two)
    public static let signalSoh: Key_Event = .ctrl(.a)
    public static let signalStx: Key_Event = .ctrl(.b)
    public static let signalInt: Key_Event = .ctrl(.c)
    public static let signalEot: Key_Event = .ctrl(.d)
    public static let signalEnq: Key_Event = .ctrl(.e)
    public static let signalAck: Key_Event = .ctrl(.f)
    public static let signalBel: Key_Event = .ctrl(.g)
    // public static let signalBs: Key_Event = .ctrl(.backspace)
    public static let signalLf: Key_Event = .ctrl(.j)
    public static let signalVt: Key_Event = .ctrl(.k)
    public static let signalFf: Key_Event = .ctrl(.l)
    public static let signalSo: Key_Event = .ctrl(.n)
    public static let signalDiscard: Key_Event = .ctrl(.o)
    public static let signalDle: Key_Event = .ctrl(.p)
    public static let signalStart: Key_Event = .ctrl(.q)
    public static let signalReprint: Key_Event = .ctrl(.r)
    public static let signalStop: Key_Event = .ctrl(.s)
    public static let signalInfo: Key_Event = .ctrl(.t)
    public static let signalKill: Key_Event = .ctrl(.u)
    public static let signalNext: Key_Event = .ctrl(.v)
    public static let signalEtb: Key_Event = .ctrl(.w)
    public static let signalCancel: Key_Event = .ctrl(.x)
    public static let signalDsusp: Key_Event = .ctrl(.y)
    public static let signalSuspend: Key_Event = .ctrl(.z)
    public static let signalQuit: Key_Event = .ctrl(.backslash)
    public static let signalGs: Key_Event = .ctrl(.rightBracket)
    public static let signalRs: Key_Event = .ctrl(.caret)
    public static let signalUs: Key_Event = .ctrl(.underscore)
    public static let signalH: Key_Event = .ctrl(.h)

    // shorthand for meta/function keys
    public static let tab: Key_Event = .fn(.tab)
    public static let enter: Key_Event = .fn(.enter)
    public static let esc: Key_Event = .fn(.esc)
    public static let backspace: Key_Event = .fn(.backspace)
    public static let backtab: Key_Event = .fn(.backtab)
    public static let down: Key_Event = .fn(.down)
    public static let up: Key_Event = .fn(.up)
    public static let left: Key_Event = .fn(.left)
    public static let right: Key_Event = .fn(.right)
    public static let home: Key_Event = .fn(.home)
    public static let f1: Key_Event = .fn(.f1)
    public static let f2: Key_Event = .fn(.f2)
    public static let f3: Key_Event = .fn(.f3)
    public static let f4: Key_Event = .fn(.f4)
    public static let f5: Key_Event = .fn(.f5)
    public static let f6: Key_Event = .fn(.f6)
    public static let f7: Key_Event = .fn(.f7)
    public static let f8: Key_Event = .fn(.f8)
    public static let f9: Key_Event = .fn(.f9)
    public static let f10: Key_Event = .fn(.f10)
    public static let f11: Key_Event = .fn(.f11)
    public static let f12: Key_Event = .fn(.f12)
    public static let pageDown: Key_Event = .fn(.pageDown)
    public static let pageUp: Key_Event = .fn(.pageUp)
    public static let end: Key_Event = .fn(.end)
    public static let delete: Key_Event = .fn(.delete)
    public static let insert: Key_Event = .fn(.insert)

    // shorthand for printables
    public static let space: Key_Event = .char(.space)
    public static let bang: Key_Event = .char(.bang)
    public static let doubleQuote: Key_Event = .char(.doubleQuote)
    public static let hash: Key_Event = .char(.hash)
    public static let dollar: Key_Event = .char(.dollar)
    public static let percent: Key_Event = .char(.percent)
    public static let amp: Key_Event = .char(.amp)
    public static let singleQuote: Key_Event = .char(.singleQuote)
    public static let leftParen: Key_Event = .char(.leftParen)
    public static let rightParen: Key_Event = .char(.rightParen)
    public static let star: Key_Event = .char(.star)
    public static let plus: Key_Event = .char(.plus)
    public static let comma: Key_Event = .char(.comma)
    public static let dash: Key_Event = .char(.dash)
    public static let dot: Key_Event = .char(.dot)
    public static let number0: Key_Event = .char(.number0)
    public static let number1: Key_Event = .char(.number1)
    public static let number2: Key_Event = .char(.number2)
    public static let number3: Key_Event = .char(.number3)
    public static let number4: Key_Event = .char(.number4)
    public static let number5: Key_Event = .char(.number5)
    public static let number6: Key_Event = .char(.number6)
    public static let number7: Key_Event = .char(.number7)
    public static let number8: Key_Event = .char(.number8)
    public static let number9: Key_Event = .char(.number9)
    public static let colon: Key_Event = .char(.colon)
    public static let semicolon: Key_Event = .char(.semicolon)
    public static let lt: Key_Event = .char(.lt)
    public static let eq: Key_Event = .char(.eq)
    public static let gt: Key_Event = .char(.gt)
    public static let question: Key_Event = .char(.question)
    public static let at: Key_Event = .char(.at)
    public static let A: Key_Event = .char(.A)
    public static let B: Key_Event = .char(.B)
    public static let C: Key_Event = .char(.C)
    public static let D: Key_Event = .char(.D)
    public static let E: Key_Event = .char(.E)
    public static let F: Key_Event = .char(.F)
    public static let G: Key_Event = .char(.G)
    public static let H: Key_Event = .char(.H)
    public static let I: Key_Event = .char(.I)
    public static let J: Key_Event = .char(.J)
    public static let K: Key_Event = .char(.K)
    public static let L: Key_Event = .char(.L)
    public static let M: Key_Event = .char(.M)
    public static let N: Key_Event = .char(.N)
    public static let O: Key_Event = .char(.O)
    public static let P: Key_Event = .char(.P)
    public static let Q: Key_Event = .char(.Q)
    public static let R: Key_Event = .char(.R)
    public static let S: Key_Event = .char(.S)
    public static let T: Key_Event = .char(.T)
    public static let U: Key_Event = .char(.U)
    public static let V: Key_Event = .char(.V)
    public static let W: Key_Event = .char(.W)
    public static let X: Key_Event = .char(.X)
    public static let Y: Key_Event = .char(.Y)
    public static let Z: Key_Event = .char(.Z)
    public static let leftBracket: Key_Event = .char(.leftBracket)
    public static let backslash: Key_Event = .char(.backslash)
    public static let rightBracket: Key_Event = .char(.rightBracket)
    public static let caret: Key_Event = .char(.caret)
    public static let underscore: Key_Event = .char(.underscore)
    public static let backtick: Key_Event = .char(.backtick)
    public static let a: Key_Event = .char(.a)
    public static let b: Key_Event = .char(.b)
    public static let c: Key_Event = .char(.c)
    public static let d: Key_Event = .char(.d)
    public static let e: Key_Event = .char(.e)
    public static let f: Key_Event = .char(.f)
    public static let g: Key_Event = .char(.g)
    public static let h: Key_Event = .char(.h)
    public static let i: Key_Event = .char(.i)
    public static let j: Key_Event = .char(.j)
    public static let k: Key_Event = .char(.k)
    public static let l: Key_Event = .char(.l)
    public static let m: Key_Event = .char(.m)
    public static let n: Key_Event = .char(.n)
    public static let o: Key_Event = .char(.o)
    public static let p: Key_Event = .char(.p)
    public static let q: Key_Event = .char(.q)
    public static let r: Key_Event = .char(.r)
    public static let s: Key_Event = .char(.s)
    public static let t: Key_Event = .char(.t)
    public static let u: Key_Event = .char(.u)
    public static let v: Key_Event = .char(.v)
    public static let w: Key_Event = .char(.w)
    public static let x: Key_Event = .char(.x)
    public static let y: Key_Event = .char(.y)
    public static let z: Key_Event = .char(.z)
    public static let leftCurly: Key_Event = .char(.leftCurly)
    public static let pipe: Key_Event = .char(.pipe)
    public static let rightCurly: Key_Event = .char(.rightCurly)
    public static let tilde: Key_Event = .char(.tilde)
}

extension Key_Event: Equatable {
    public static func == (lhs: Key_Event, rhs: Key_Event) -> Bool {
        lhs.toString == rhs.toString
    }
}

public extension Key_Event {
    var isPrintable: Bool {
        switch self {
        case let .alt(key):
            return key.isPrintable
        case .char:
            return true
        default:
            return false
        }
    }

    var toPrintable: String {
        switch self {
        case let .alt(key): return "\(key.toPrintable)"
        case let .char(key): return "\(key.toPrintable)"
        case let .fn(key): return "\(key.toPrintable)"
        default:
            return toString
        }
    }

    var toString: String {
        switch self {
        case let .ctrl(key): return "⌃\(key.toString.uppercased())"
        case let .alt(key): return "⌥\(key.toString)"
        case let .shift(key): return "⇧\(key.toString)"
        case let .char(key): return "\(key.toString)"
        case let .fn(key): return "\(key.toString)"
        }
    }
}

public enum CtrlKey_Event: Hashable {
    case alt(AltKey_Event)
    case two
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case j
    case k
    case l
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z
    case backslash
    case rightBracket
    case caret
    case underscore
    case six
    case home
    case end
}

public extension CtrlKey_Event {
    var toString: String {
        switch self {
        case let .alt(key): return "⌥\(key.toString)"
        case .two: return "2"
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .backslash: return "\\"
        case .rightBracket: return "]"
        case .caret: return "^"
        case .underscore: return "_"
        case .h: return "H"
        case .six: return "6"
        case .home: return "⤒"
        case .end: return "⤓"
        }
    }
}

extension CtrlKey_Event: Equatable {
    public static func == (lhs: CtrlKey_Event, rhs: CtrlKey_Event) -> Bool {
        lhs.toString == rhs.toString
    }
}

public enum AltKey_Event: Hashable {
    case shift(ShiftKey_Event)
    case char(CharKey_Event)
    case fn(FnKey_Event)

    // shorthand for meta/function keys
    public static let tab: AltKey_Event = .fn(.tab)
    public static let enter: AltKey_Event = .fn(.enter)
    public static let esc: AltKey_Event = .fn(.esc)
    public static let backspace: AltKey_Event = .fn(.backspace)
    public static let backtab: AltKey_Event = .fn(.backtab)
    public static let down: AltKey_Event = .fn(.down)
    public static let up: AltKey_Event = .fn(.up)
    public static let left: AltKey_Event = .fn(.left)
    public static let right: AltKey_Event = .fn(.right)
    public static let home: AltKey_Event = .fn(.home)
    public static let f1: AltKey_Event = .fn(.f1)
    public static let f2: AltKey_Event = .fn(.f2)
    public static let f3: AltKey_Event = .fn(.f3)
    public static let f4: AltKey_Event = .fn(.f4)
    public static let f5: AltKey_Event = .fn(.f5)
    public static let f6: AltKey_Event = .fn(.f6)
    public static let f7: AltKey_Event = .fn(.f7)
    public static let f8: AltKey_Event = .fn(.f8)
    public static let f9: AltKey_Event = .fn(.f9)
    public static let f10: AltKey_Event = .fn(.f10)
    public static let f11: AltKey_Event = .fn(.f11)
    public static let f12: AltKey_Event = .fn(.f12)
    public static let pageDown: AltKey_Event = .fn(.pageDown)
    public static let pageUp: AltKey_Event = .fn(.pageUp)
    public static let end: AltKey_Event = .fn(.end)
    public static let delete: AltKey_Event = .fn(.delete)
    public static let insert: AltKey_Event = .fn(.insert)

    // shorthand for printables
    public static let space: AltKey_Event = .char(.space)
    public static let bang: AltKey_Event = .char(.bang)
    public static let doubleQuote: AltKey_Event = .char(.doubleQuote)
    public static let hash: AltKey_Event = .char(.hash)
    public static let dollar: AltKey_Event = .char(.dollar)
    public static let percent: AltKey_Event = .char(.percent)
    public static let amp: AltKey_Event = .char(.amp)
    public static let singleQuote: AltKey_Event = .char(.singleQuote)
    public static let leftParen: AltKey_Event = .char(.leftParen)
    public static let rightParen: AltKey_Event = .char(.rightParen)
    public static let star: AltKey_Event = .char(.star)
    public static let plus: AltKey_Event = .char(.plus)
    public static let comma: AltKey_Event = .char(.comma)
    public static let dash: AltKey_Event = .char(.dash)
    public static let dot: AltKey_Event = .char(.dot)
    public static let number0: AltKey_Event = .char(.number0)
    public static let number1: AltKey_Event = .char(.number1)
    public static let number2: AltKey_Event = .char(.number2)
    public static let number3: AltKey_Event = .char(.number3)
    public static let number4: AltKey_Event = .char(.number4)
    public static let number5: AltKey_Event = .char(.number5)
    public static let number6: AltKey_Event = .char(.number6)
    public static let number7: AltKey_Event = .char(.number7)
    public static let number8: AltKey_Event = .char(.number8)
    public static let number9: AltKey_Event = .char(.number9)
    public static let colon: AltKey_Event = .char(.colon)
    public static let semicolon: AltKey_Event = .char(.semicolon)
    public static let lt: AltKey_Event = .char(.lt)
    public static let eq: AltKey_Event = .char(.eq)
    public static let gt: AltKey_Event = .char(.gt)
    public static let question: AltKey_Event = .char(.question)
    public static let at: AltKey_Event = .char(.at)
    public static let A: AltKey_Event = .char(.A)
    public static let B: AltKey_Event = .char(.B)
    public static let C: AltKey_Event = .char(.C)
    public static let D: AltKey_Event = .char(.D)
    public static let E: AltKey_Event = .char(.E)
    public static let F: AltKey_Event = .char(.F)
    public static let G: AltKey_Event = .char(.G)
    public static let H: AltKey_Event = .char(.H)
    public static let I: AltKey_Event = .char(.I)
    public static let J: AltKey_Event = .char(.J)
    public static let K: AltKey_Event = .char(.K)
    public static let L: AltKey_Event = .char(.L)
    public static let M: AltKey_Event = .char(.M)
    public static let N: AltKey_Event = .char(.N)
    public static let O: AltKey_Event = .char(.O)
    public static let P: AltKey_Event = .char(.P)
    public static let Q: AltKey_Event = .char(.Q)
    public static let R: AltKey_Event = .char(.R)
    public static let S: AltKey_Event = .char(.S)
    public static let T: AltKey_Event = .char(.T)
    public static let U: AltKey_Event = .char(.U)
    public static let V: AltKey_Event = .char(.V)
    public static let W: AltKey_Event = .char(.W)
    public static let X: AltKey_Event = .char(.X)
    public static let Y: AltKey_Event = .char(.Y)
    public static let Z: AltKey_Event = .char(.Z)
    public static let leftBracket: AltKey_Event = .char(.leftBracket)
    public static let backslash: AltKey_Event = .char(.backslash)
    public static let rightBracket: AltKey_Event = .char(.rightBracket)
    public static let caret: AltKey_Event = .char(.caret)
    public static let underscore: AltKey_Event = .char(.underscore)
    public static let backtick: AltKey_Event = .char(.backtick)
    public static let a: AltKey_Event = .char(.a)
    public static let b: AltKey_Event = .char(.b)
    public static let c: AltKey_Event = .char(.c)
    public static let d: AltKey_Event = .char(.d)
    public static let e: AltKey_Event = .char(.e)
    public static let f: AltKey_Event = .char(.f)
    public static let g: AltKey_Event = .char(.g)
    public static let h: AltKey_Event = .char(.h)
    public static let i: AltKey_Event = .char(.i)
    public static let j: AltKey_Event = .char(.j)
    public static let k: AltKey_Event = .char(.k)
    public static let l: AltKey_Event = .char(.l)
    public static let m: AltKey_Event = .char(.m)
    public static let n: AltKey_Event = .char(.n)
    public static let o: AltKey_Event = .char(.o)
    public static let p: AltKey_Event = .char(.p)
    public static let q: AltKey_Event = .char(.q)
    public static let r: AltKey_Event = .char(.r)
    public static let s: AltKey_Event = .char(.s)
    public static let t: AltKey_Event = .char(.t)
    public static let u: AltKey_Event = .char(.u)
    public static let v: AltKey_Event = .char(.v)
    public static let w: AltKey_Event = .char(.w)
    public static let x: AltKey_Event = .char(.x)
    public static let y: AltKey_Event = .char(.y)
    public static let z: AltKey_Event = .char(.z)
    public static let leftCurly: AltKey_Event = .char(.leftCurly)
    public static let pipe: AltKey_Event = .char(.pipe)
    public static let rightCurly: AltKey_Event = .char(.rightCurly)
    public static let tilde: AltKey_Event = .char(.tilde)
}

public extension AltKey_Event {
    var isPrintable: Bool {
        toPrintable != ""
    }

    var toPrintable: String {
        switch self {
        case .char(.a): return "å"
        case .char(.b): return "∫"
        case .char(.c): return "ç"
        case .char(.d): return "∂"
        case .char(.e): return "󰀀" // uF0000, combining ´
        case .char(.f): return "ƒ"
        case .char(.g): return "©"
        case .char(.h): return "˙"
        case .char(.i): return "󰀁" // uF0001, combining ˆ
        case .char(.j): return "∆"
        case .char(.k): return "˚"
        case .char(.l): return "¬"
        case .char(.m): return "µ"
        case .char(.n): return "󰀂" // uF0002, combining ˜
        case .char(.o): return "ø"
        case .char(.p): return "π"
        case .char(.q): return "œ"
        case .char(.r): return "®"
        case .char(.s): return "ß"
        case .char(.t): return "†"
        case .char(.u): return "󰀃" // uF0003, combining ¨
        case .char(.v): return "√"
        case .char(.w): return "∑"
        case .char(.x): return "≈"
        case .char(.y): return "¥"
        case .char(.z): return "Ω"
        case .char(.backtick): return "󰀄" // uF0004, combining `
        case .char(.number1): return "¡"
        case .char(.number2): return "™"
        case .char(.number3): return "£"
        case .char(.number4): return "¢"
        case .char(.number5): return "∞"
        case .char(.number6): return "§"
        case .char(.number7): return "¶"
        case .char(.number8): return "•"
        case .char(.number9): return "ª"
        case .char(.number0): return "º"
        case .char(.dash): return "–"
        case .char(.eq): return "≠"
        case .char(.leftBracket): return "“"
        case .char(.rightBracket): return "‘"
        case .char(.backslash): return "«"
        case .char(.semicolon): return "…"
        case .char(.singleQuote): return "æ"
        case .char(.comma): return "≤"
        case .char(.dot): return "≥"
        case .char(.slash): return "÷"
        // shifted
        case .char(.A): return "Å"
        case .char(.B): return "ı"
        case .char(.C): return "Ç"
        case .char(.D): return "Î"
        case .char(.E): return "´"
        case .char(.F): return "Ï"
        case .char(.G): return "˝"
        case .char(.H): return "Ó"
        case .char(.I): return "ˆ"
        case .char(.J): return "Ô"
        case .char(.K): return ""
        case .char(.L): return "Ò"
        case .char(.M): return "Â"
        case .char(.N): return "˜"
        case .char(.O): return "Ø"
        case .char(.P): return "∏"
        case .char(.Q): return "Œ"
        case .char(.R): return "‰"
        case .char(.S): return "Í"
        case .char(.T): return "ˇ"
        case .char(.U): return "¨"
        case .char(.V): return "◊"
        case .char(.W): return "„"
        case .char(.X): return "˛"
        case .char(.Y): return "Á"
        case .char(.Z): return "¸"
        case .char(.tilde): return "~"
        case .char(.bang): return "⁄"
        case .char(.at): return "€"
        case .char(.hash): return "‹"
        case .char(.dollar): return "›"
        case .char(.percent): return "ﬁ"
        case .char(.caret): return "ﬂ"
        case .char(.amp): return "‡"
        case .char(.star): return "°"
        case .char(.leftParen): return "·"
        case .char(.rightParen): return "‚"
        case .char(.underscore): return "—"
        case .char(.plus): return "±"
        case .char(.leftCurly): return "”"
        case .char(.rightCurly): return "’"
        case .char(.pipe): return "»"
        case .char(.colon): return "Ú"
        case .char(.doubleQuote): return "Æ"
        case .char(.lt): return "¯"
        case .char(.gt): return "˘"
        case .char(.question): return "¿"
        default:
            return ""
        }
    }

    var toString: String {
        switch self {
        case let .shift(key): return "⇧\(key.toString)"
        case let .char(key): return key.toString
        case let .fn(key): return key.toString
        }
    }
}

extension AltKey_Event: Equatable {
    public static func == (lhs: AltKey_Event, rhs: AltKey_Event) -> Bool {
        lhs.toString == rhs.toString
    }
}

public enum ShiftKey_Event: Hashable {
    case down
    case up
    case left
    case right
    case home
    case end
}

public extension ShiftKey_Event {
    var toString: String {
        switch self {
        case .down: return "↓"
        case .up: return "↑"
        case .left: return "←"
        case .right: return "→"
        case .home: return "⤒"
        case .end: return "⤓"
        }
    }
}

extension ShiftKey_Event: Equatable {
    public static func == (lhs: ShiftKey_Event, rhs: ShiftKey_Event) -> Bool {
        lhs.toString == rhs.toString
    }
}

public enum CharKey_Event: UInt16, Hashable {
    case space = 32
    case bang
    case doubleQuote
    case hash
    case dollar
    case percent
    case amp
    case singleQuote
    case leftParen
    case rightParen
    case star
    case plus
    case comma
    case dash
    case dot
    case slash

    case number0
    case number1
    case number2
    case number3
    case number4
    case number5
    case number6
    case number7
    case number8
    case number9

    case colon
    case semicolon
    case lt
    case eq
    case gt
    case question
    case at

    case A
    case B
    case C
    case D
    case E
    case F
    case G
    case H
    case I
    case J
    case K
    case L
    case M
    case N
    case O
    case P
    case Q
    case R
    case S
    case T
    case U
    case V
    case W
    case X
    case Y
    case Z

    case leftBracket
    case backslash
    case rightBracket
    case caret
    case underscore
    case backtick

    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z

    case leftCurly
    case pipe
    case rightCurly
    case tilde
}

public extension CharKey_Event {
    var toPrintable: String {
        if case .space = self {
            return " "
        }
        return toString
    }

    var toString: String {
        switch self {
        case .space: return "␣"

        case .bang: return "!"
        case .doubleQuote: return "\""
        case .hash: return "#"
        case .dollar: return "$"
        case .percent: return "%"
        case .amp: return "&"
        case .singleQuote: return "'"
        case .leftParen: return "("
        case .rightParen: return ")"
        case .star: return "*"
        case .plus: return "+"
        case .comma: return ","
        case .dash: return "-"
        case .dot: return "."
        case .slash: return "/"

        case .colon: return ":"
        case .semicolon: return ";"
        case .lt: return "<"
        case .eq: return "="
        case .gt: return ">"
        case .question: return "?"
        case .at: return "@"

        case .leftBracket: return "["
        case .backslash: return "\\"
        case .rightBracket: return "]"
        case .caret: return "^"
        case .underscore: return "_"
        case .backtick: return "`"

        case .leftCurly: return "{"
        case .pipe: return "|"
        case .rightCurly: return "}"
        case .tilde: return "~"

        case .number0: return "0"
        case .number1: return "1"
        case .number2: return "2"
        case .number3: return "3"
        case .number4: return "4"
        case .number5: return "5"
        case .number6: return "6"
        case .number7: return "7"
        case .number8: return "8"
        case .number9: return "9"

        case .A: return "A"
        case .B: return "B"
        case .C: return "C"
        case .D: return "D"
        case .E: return "E"
        case .F: return "F"
        case .G: return "G"
        case .H: return "H"
        case .I: return "I"
        case .J: return "J"
        case .K: return "K"
        case .L: return "L"
        case .M: return "M"
        case .N: return "N"
        case .O: return "O"
        case .P: return "P"
        case .Q: return "Q"
        case .R: return "R"
        case .S: return "S"
        case .T: return "T"
        case .U: return "U"
        case .V: return "V"
        case .W: return "W"
        case .X: return "X"
        case .Y: return "Y"
        case .Z: return "Z"

        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        case .d: return "d"
        case .e: return "e"
        case .f: return "f"
        case .g: return "g"
        case .h: return "h"
        case .i: return "i"
        case .j: return "j"
        case .k: return "k"
        case .l: return "l"
        case .m: return "m"
        case .n: return "n"
        case .o: return "o"
        case .p: return "p"
        case .q: return "q"
        case .r: return "r"
        case .s: return "s"
        case .t: return "t"
        case .u: return "u"
        case .v: return "v"
        case .w: return "w"
        case .x: return "x"
        case .y: return "y"
        case .z: return "z"
        }
    }
}

public enum FnKey_Event: Hashable {
    case tab
    case enter
    case esc
    case backspace
    case backtab

    case down
    case up
    case left
    case right

    case f1
    case f2
    case f3
    case f4
    case f5
    case f6
    case f7
    case f8
    case f9
    case f10
    case f11
    case f12

    case home
    case pageDown
    case pageUp
    case end
    case delete
    case insert
}

public extension FnKey_Event {
    var toPrintable: String {
        switch self {
        case .enter:
            return "\n"
        default:
            return ""
        }
    }

    var toString: String {
        switch self {
        case .tab: return "⇥"
        case .enter: return "↩︎"
        case .esc: return "⎋"
        case .backspace: return "⌫"
        case .backtab: return "⇤"

        case .down: return "↓"
        case .up: return "↑"
        case .left: return "←"
        case .right: return "→"

        case .f1: return "𝔽1"
        case .f2: return "𝔽2"
        case .f3: return "𝔽3"
        case .f4: return "𝔽4"
        case .f5: return "𝔽5"
        case .f6: return "𝔽6"
        case .f7: return "𝔽7"
        case .f8: return "𝔽8"
        case .f9: return "𝔽9"
        case .f10: return "𝔽10"
        case .f11: return "𝔽11"
        case .f12: return "𝔽12"

        case .home: return "⤒"
        case .pageUp: return "↟"
        case .pageDown: return "↡"
        case .end: return "⤓"
        case .delete: return "⌦"
        case .insert: return "⌅"
        }
    }
}

extension Key_Event: CustomStringConvertible {
    public var description: String { toString }
}

extension CtrlKey_Event: CustomStringConvertible {
    public var description: String { toString }
}

extension AltKey_Event: CustomStringConvertible {
    public var description: String { toString }
}

extension ShiftKey_Event: CustomStringConvertible {
    public var description: String { toString }
}

extension CharKey_Event: CustomStringConvertible {
    public var description: String { toString }
}

extension FnKey_Event: CustomStringConvertible {
    public var description: String { toString }
}
