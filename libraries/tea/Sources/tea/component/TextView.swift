import Foundation
import os.log

public class TextView<Message>: View<Message> {
    let chars: TextType

    public init(_ text: TextType, events: [ViewEvent<Message>] = [], layoutPolicy: LayoutPolicy = LayoutPolicy()) {
        chars = text
        super.init(events, layoutPolicy)
    }

    override func measure(availableSize: Size) -> Size {
        let size = Size(width: min(chars.count, availableSize.width), height: 1)
        measureStatus = .Measured(size)
        return size
    }

    override func renderTo(buffer: Buffer<Message>, in rect: Rect, events: [ViewEvent<Message>]) {
        for i in 0 ..< chars.count {
            buffer.write(chars[i], events + self.events, x: rect.x + i, y: rect.y)
        }
    }
}

func EmptyLine<Message>() -> TextView<Message> {
    TextView("")
}
