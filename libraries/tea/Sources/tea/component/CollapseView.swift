import Foundation
import os.log

public class CollapseView<Message>: View<Message> {
    let open: Bool
    let content: [View<Message>]

    public init(content: [View<Message>], open: Bool) {
        self.open = open
        self.content = content
    }

    override func measure(availableSize: Size) -> Size {
        if open {
            let sizes = content.map { $0.measure(availableSize: availableSize) }
            let width = sizes.map { $0.width }.sorted(by: >).first!
            let height = sizes.count
            let size = Size(width: width, height: height)
            measureStatus = .Measured(size)
            return size
        } else {
            let size = content.first!.measure(availableSize: availableSize)
            measureStatus = .Measured(size)
            return size
        }
    }

    override func renderTo(buffer: Buffer<Message>, in rect: Rect, events: [ViewEvent<Message>]) {
        if open {
            var yOffset = rect.y
            for view in content {
                switch view.measureStatus {
                case .NotMeasured:
                    os_log("Found unmeasured view, skipping")
                case let .Measured(viewSize):
                    view.renderTo(buffer: buffer, in: Rect(0, yOffset, viewSize.width, viewSize.height), events: events + self.events)
                    yOffset += viewSize.height
                }
            }
        } else {
            content.first!.renderTo(buffer: buffer, in: rect, events: events + self.events)
        }
    }
}
