import Foundation

public typealias ViewEvent<Message> = (KeyEvent, Message)

public enum MeasureStatus: Equatable {
    case NotMeasured
    case Measured(Size)
}

public class View<Message>: Equatable {
    let events: [ViewEvent<Message>]
    let layoutPolicy: LayoutPolicy
    var measureStatus: MeasureStatus = .NotMeasured

    init(_ events: [ViewEvent<Message>] = [], _ layoutPolicy: LayoutPolicy = LayoutPolicy()) {
        self.events = events
        self.layoutPolicy = layoutPolicy
    }

    func measure(availableSize _: Size) -> Size {
        let size = Size(width: 0, height: 0)
        measureStatus = .Measured(size)
        return size
    }

    func renderTo(buffer _: Buffer<Message>, in _: Rect, events _: [ViewEvent<Message>]) {
        // do nothing
    }

    public static func == (lhs: View<Message>, rhs: View<Message>) -> Bool {
        lhs.layoutPolicy == rhs.layoutPolicy
            && lhs.measureStatus == rhs.measureStatus
    }
}
