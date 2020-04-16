import Foundation

public enum CursorVerticalDirection {
    case up
    case down
}

public class Buffer {
    typealias Chars = [Int: [Int: AttrCharType]]
    //typealias Mouse = [Int: [Int: (Component, Point)]]
    private(set) var chars: Chars = [:]
    //private(set) var mouse: Mouse = [:]
    //private var offset: Point = .zero
    //private var zeroOrigin: Point = .zero
    private var size: Size
    private(set) var cursor: (UInt, UInt)

    init(size: Size) {
        self.size = size
        self.cursor = (0, 0)
    }

    /*public func claimMouse(rect: Rect, component: Component) {
        for localY in rect.origin.y..<rect.origin.y + rect.size.height {
            let y = offset.y + localY
            guard y >= zeroOrigin.y, y < offset.y + size.height else { continue }
            var row = mouse[y] ?? [:]

            for localX in rect.origin.x..<rect.origin.x + rect.size.width {
                let x = offset.x + localX
                guard
                    x >= zeroOrigin.x,
                    x < offset.x + size.width,
                    row[x] == nil
                else { continue }

                row[x] = (component, rect.origin + offset)
            }

            mouse[y] = row
        }
    }

    public func push(offset nextOffset: Point, clip nextDesiredSize: Size, _ block: () -> Void) {
        guard nextOffset.x < size.width, nextOffset.y < size.height else { return }
        let nextSize = Size(
            width: min(size.width - nextOffset.x, nextDesiredSize.width),
            height: min(size.height - nextOffset.y, nextDesiredSize.height)
        )
        guard nextOffset.x + nextSize.width > 0, nextOffset.y + nextSize.height > 0 else { return }
        guard nextSize.width > 0, nextSize.height > 0 else { return }

        let prevOffset = offset
        let prevZeroOrigin = zeroOrigin
        let prevSize = size
        offset = Point(
            x: offset.x + nextOffset.x,
            y: offset.y + nextOffset.y
        )
        zeroOrigin = Point(
            x: max(zeroOrigin.x, offset.x),
            y: max(zeroOrigin.y, offset.y)
        )
        size = nextSize
        block()
        offset = prevOffset
        zeroOrigin = prevZeroOrigin
        size = prevSize
    }*/
    
    public func clear() {
        chars = [:]
    }
    
    public func moveCursor(_ direction: CursorVerticalDirection) {
        switch direction {
        case .up:
            if cursor.1 > 0 {
                cursor = (cursor.0, cursor.1 - 1)
            }
        case .down:
            if cursor.1 < size.height - 1 {
                cursor = (cursor.0, cursor.1 + 1)
            }
        }
    }
    
    public func updateCursor(x: UInt, y: UInt) {
        guard
            x < size.width,
            y < size.height
        else { return }
        
        cursor = (x, y)
    }

    public func write(_ attrChar: AttrCharType, x localX: Int, y localY: Int) {
        guard
            attrChar.char != "",
            localX >= 0, localY >= 0,
                localX < size.width, localY < size.height
        else { return }

        let x = localX// + offset.x
        let y = localY// + offset.y
        guard
            x >= 0, y >= 0
        else { return }

        var row = chars[y] ?? [:]
        /*if let prevText = row[x] {
            if prevText.char == nil, let char = attrChar.char {
                row[x] = AttrChar(char, prevText.attrs)
            }
        }
        else {*/
        /*if x == cursor.0 && y == cursor.1 {
            row[x] = AttrChar(attrChar.char, [.background(Color.white), .foreground(Color.black)])
        } else {*/
            row[x] = attrChar
        //}
        //}
        chars[y] = row
    }
    
    public func write(lines: [AttrCharType]) {
        for y in 0..<lines.count {
            let line: AttrCharType = lines[y]
            for x in 0..<(line.char?.count ?? 0) {
                if let char = line.char?[x] {
                    write(char, x: x, y: y)
                }
            }
        }
    }
    
    public func read(x: Int, y: Int) -> AttrCharType {
        chars[y]![x]!
    }
}

extension Buffer: CustomStringConvertible {
    public var description: String {
        var description = ""
        for j in 0..<size.height {
            for i in 0..<size.width {
                guard
                    let c = (chars[j] ?? [:])[i],
                    let char = c.char
                else {
                    description += " "
                    continue
                }
                description += char
            }
            description += "\n"
        }
        return description
    }
}
