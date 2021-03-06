import Termbox

class TermboxScreen {
    public var size: Size { Size(width: Int(Termbox.width), height: Int(Termbox.height)) }

    public init() {}

    public func setup() throws {
        try Termbox.initialize()
        Termbox.outputMode = .color256
        Termbox.clear(foreground: .default, background: .default)
        Termbox.render()
    }

    public func teardown() {
        Termbox.shutdown()
    }

    public func render(buffer: Matrix<Char>) {
        Termbox.clear()

        for y in 0 ..< buffer.rows {
            for x in 0 ..< buffer.columns {
                guard
                    y >= 0, y < size.height,
                    x >= 0, x < size.width
                else { continue }

                let char = buffer[y, x]
                Termbox.putc(
                    x: Int32(x),
                    y: Int32(y),
                    char: char.unicodeScalar(),
                    foreground: char.foreground.toTermbox,
                    background: char.background.toTermbox
                )
            }
        }

        Termbox.render()
    }

    func pollEvent() -> Event? {
        let termboxEvent = Termbox.pollEvent()
        return convertTermboxEvent(termboxEvent)
    }

    func nextEvent() -> Event? {
        let termboxEvent = Termbox.peekEvent(timeoutInMilliseconds: 10)
        return convertTermboxEvent(termboxEvent)
    }

    private func convertTermboxEvent(_ termboxEvent: TermboxEvent) -> Event? {
        switch termboxEvent {
        case let .key(mod, value):
            if let key = termboxKey(mod, value) {
                return .Key(key)
            }
        case let .character(mod, value):
            guard let key = termboxCharacter(mod, value) else { return nil }
            return .Key(key)
        case let .resize(width, height):
            return .Window(width: Int(width), height: Int(height))
        default:
            break
        }
        return nil
    }
}

/* private func foregroundAttrs(_ attrs: [Attr]) -> Attributes {
     let retval = attrs.reduce(Attributes.zero) { memo, attr -> Attributes in
         switch attr {
         case .foreground(.normal):
             return memo.union(Attributes.default)
         case .background:
             return memo
         default:
             return memo.union(attr.toTermbox)
         }
     }
     return retval
 }

 private func backgroundAttrs(_ attrs: [Attr]) -> Attributes {
     let retval = attrs.reduce(Attributes.zero) { memo, attr -> Attributes in
         switch attr {
         case .background(.normal):
             return memo.union(Attributes.default)
         case .foreground:
             return memo
         default:
             return memo.union(attr.toTermbox)
         }
     }
     return retval
 } */

private func termboxKey(_ mod: TermboxModifier, _ key: TermboxKey) -> KeyEvent? {
    switch (mod, key) {
    case (.ctrl, .ctrl2):
        return .ctrl(.two)
    case (.ctrl, .ctrlA):
        return .ctrl(.a)
    case (.ctrl, .ctrlB):
        return .ctrl(.b)
    case (.ctrl, .ctrlC):
        return .ctrl(.c)
    case (.ctrl, .ctrlD):
        return .ctrl(.d)
    case (.ctrl, .ctrlE):
        return .ctrl(.e)
    case (.ctrl, .ctrlF):
        return .ctrl(.f)
    case (.ctrl, .ctrlG):
        return .ctrl(.g)
    case (.ctrl, .ctrlJ):
        return .ctrl(.j)
    case (.ctrl, .ctrlK):
        return .ctrl(.k)
    case (.ctrl, .ctrlL):
        return .ctrl(.l)
    case (.none, .enter):
        return .enter
    case (.ctrl, .ctrlN):
        return .ctrl(.n)
    case (.ctrl, .ctrlO):
        return .ctrl(.o)
    case (.ctrl, .ctrlP):
        return .ctrl(.p)
    case (.ctrl, .ctrlQ):
        return .ctrl(.q)
    case (.ctrl, .ctrlR):
        return .ctrl(.r)
    case (.ctrl, .ctrlS):
        return .ctrl(.s)
    case (.ctrl, .ctrlT):
        return .ctrl(.t)
    case (.ctrl, .ctrlU):
        return .ctrl(.u)
    case (.ctrl, .ctrlV):
        return .ctrl(.v)
    case (.ctrl, .ctrlW):
        return .ctrl(.w)
    case (.ctrl, .ctrlX):
        return .ctrl(.x)
    case (.ctrl, .ctrlY):
        return .ctrl(.y)
    case (.ctrl, .ctrlZ):
        return .ctrl(.z)
    case (.ctrl, .ctrlBackslash):
        return .ctrl(.backslash)
    case (.ctrl, .ctrlRightBracket):
        return .ctrl(.rightBracket)
    case (.ctrl, .ctrl6):
        return .ctrl(.six)
    case (.ctrl, .ctrlSlash):
        return .ctrl(.underscore)
    case (.none, .backspace):
        return .backspace
    case (.alt, .backspace):
        return .alt(.backspace)
    case (.ctrl, .tab):
        return .tab
    case (.shift, .tab):
        return .backtab
    case (.altCtrl, .tab):
        return .alt(.tab)
    case (.none, .esc):
        return .esc
    case (.alt, .esc):
        return .alt(.esc)
    case (.none, .space):
        return .space
    case (.none, .f1):
        return .f1
    case (.none, .f2):
        return .f2
    case (.none, .f3):
        return .f3
    case (.none, .f4):
        return .f4
    case (.none, .f5):
        return .f5
    case (.none, .f6):
        return .f6
    case (.none, .f7):
        return .f7
    case (.none, .f8):
        return .f8
    case (.none, .f9):
        return .f9
    case (.none, .f10):
        return .f10
    case (.none, .f11):
        return .f11
    case (.none, .f12):
        return .f12
    case (.none, .insert):
        return .insert
    case (.none, .delete):
        return .delete
    case (.none, .home):
        return .home
    case (.shift, .home):
        return .shift(.home)
    case (.ctrl, .home):
        return .ctrl(.home)
    case (.altAlt, .home):
        return .alt(.home)
    case (.shiftAlt, .home):
        return .alt(.shift(.home))
    case (.none, .end):
        return .end
    case (.shift, .end):
        return .shift(.end)
    case (.ctrl, .end):
        return .ctrl(.end)
    case (.altAlt, .end):
        return .alt(.end)
    case (.shiftAlt, .end):
        return .alt(.shift(.end))
    case (.none, .pageUp):
        return .pageUp
    case (.alt, .pageUp):
        return .alt(.pageUp)
    case (.none, .pageDown):
        return .pageDown
    case (.alt, .pageDown):
        return .alt(.pageDown)
    case (.none, .arrowUp):
        return .up
    case (.shift, .arrowUp):
        return .shift(.up)
    case (.alt, .arrowUp), (.altAlt, .arrowUp):
        return .alt(.up)
    case (.shiftAlt, .arrowUp):
        return .alt(.shift(.up))
    case (.none, .arrowDown):
        return .down
    case (.shift, .arrowDown):
        return .shift(.down)
    case (.alt, .arrowDown), (.altAlt, .arrowDown):
        return .alt(.down)
    case (.shiftAlt, .arrowDown):
        return .alt(.shift(.down))
    case (.none, .arrowLeft):
        return .left
    case (.shift, .arrowLeft):
        return .shift(.left)
    case (.alt, .arrowLeft), (.altAlt, .arrowLeft):
        return .alt(.left)
    case (.shiftAlt, .arrowLeft):
        return .alt(.shift(.left))
    case (.none, .arrowRight):
        return .right
    case (.shift, .arrowRight):
        return .shift(.right)
    case (.alt, .arrowRight), (.altAlt, .arrowRight):
        return .alt(.right)
    case (.shiftAlt, .arrowRight):
        return .alt(.shift(.right))
    default:
        return nil
    }
}

private func termboxCharacter(_ mod: TermboxModifier, _ character: UnicodeScalar) -> KeyEvent? {
    switch (mod, character) {
    case (.altCtrl, "\n"):
        return .alt(.enter)
    case let (.altCtrl, character):
        guard
            character.value < UInt16.max,
            let char = CharKeyEvent(rawValue: UInt16(character.value))
        else { return nil }
        return .ctrl(.alt(.char(char)))
    case let (.alt, character):
        guard
            character.value < UInt16.max,
            let char = CharKeyEvent(rawValue: UInt16(character.value))
        else { return nil }
        return .alt(.char(char))
    case let (.altShift, character):
        guard
            character.value < UInt16.max,
            let char = CharKeyEvent(rawValue: UInt16(character.value))
        else { return nil }
        return .alt(.char(char))
    case let (_, character):
        guard
            character.value < UInt16.max,
            let char = CharKeyEvent(rawValue: UInt16(character.value))
        else { return nil }
        return .char(char)
    }
}
