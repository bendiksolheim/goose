import Foundation
import os.log

public struct BufferCell<Message> {
    let content: Char
    let events: [ViewEvent<Message>]

    init(_ content: Char, _ events: [ViewEvent<Message>]) {
        self.content = content
        self.events = events
    }

    func with(content: Char? = nil) -> BufferCell {
        BufferCell(content ?? self.content, events)
    }
}

public class Buffer<Message> {
    private(set) var chars: Matrix<BufferCell<Message>?>
    private(set) var cursors: [Cursor]
    // private var offset: Point = .zero
    // private var zeroOrigin: Point = .zero
    private(set) var size: Size

    init(size: Size) {
        self.size = size
        chars = Matrix(rows: size.height, columns: size.width, defaultValue: nil)
        cursors = []
    }

    private init(chars: Matrix<BufferCell<Message>?>) {
        self.chars = chars
        size = Size(width: chars.columns, height: chars.rows)
        cursors = []
    }

    public func clear() {
        chars = Matrix(rows: size.height, columns: size.width, defaultValue: nil)
        cursors = []
    }

    public func resize(to size: Size) {
        self.size = size
        chars = Matrix(rows: size.height, columns: size.width, defaultValue: nil)
        cursors = []
    }

    public func write(_ char: Char, _ events: [ViewEvent<Message>], x localX: Int, y localY: Int) {
        guard
            localX >= 0, localY >= 0,
            localX < size.width, localY < size.height
        else { return }

        let x = localX // + offset.x
        let y = localY // + offset.y
        guard
            x >= 0, y >= 0
        else { return }

        chars[y, x] = BufferCell(char, events)
    }

    public func addCursor(cursor: Cursor) {
        guard
            cursor.x >= 0, cursor.y >= 0,
            cursor.x < size.width, cursor.y < size.height
        else { return }

        // Colorize leftmost cell inverted
        if let cell = chars[cursor.y, cursor.x] {
            chars[cursor.y, cursor.x] = cell.with(content: cell.content.with(foreground: .black, background: .white))
            cursors.append(cursor)
        }

        // Colorize line
        for column in 1 ..< size.width {
            if let cell = chars[cursor.y, column] {
                chars[cursor.y, column] = cell.with(content: cell.content.with(background: .black))
            } else {
                chars[cursor.y, column] = BufferCell(Char(" ", .normal, .black), [])
            }
        }
    }

    public func subBuffer(rect: Rect) -> Buffer<Message> {
        let cutChars = chars[rect]
        return Buffer(chars: cutChars)
    }

    public func replaceRect(_ rect: Rect, with replacement: Buffer<Message>) {
        chars.replaceRect(rect, with: replacement.chars.grid)
    }

    public func cell(cursor: Cursor) -> BufferCell<Message>? {
        guard
            cursor.x >= 0, cursor.y >= 0,
            cursor.x < size.width, cursor.y < size.height
        else { return nil }

        return chars[cursor.y, cursor.x]
    }
}
