import Foundation
import os.log

public struct Cursor: Equatable {
    let x: Int
    let y: Int
    
    public init(_ x: Int,_ y: Int) {
        self.x = x
        self.y = y
    }
    
    func copy(withX x: Int? = nil,
              withY y: Int? = nil) -> Cursor {
        Cursor(x ?? self.x, y ?? self.y)
    }
    
    func translate(to rect: Rect) -> Cursor {
        return Cursor(rect.x + x, rect.y + y)
    }
}

/**
 This is a class because we need to mutate the height in the rendering process
 */
public class ScrollState: Equatable {
    let cursor: Cursor
    var actualHeight: Int
    var visibleHeight: Int
    var offset: Int
    
    public init(_ cursor: Cursor) {
        self.cursor = cursor
        actualHeight = 0
        visibleHeight = 0
        offset = 0
    }
    
    private init(_ cursor: Cursor, _ height: Int, _ visibleHeight: Int, _ offset: Int) {
        self.cursor = cursor
        self.actualHeight = height
        self.visibleHeight = visibleHeight
        self.offset = offset
    }
    
    func copy(withCursor cursor: Cursor? = nil) -> ScrollState {
        ScrollState(cursor ?? self.cursor, actualHeight, visibleHeight, offset)
    }
    
    public static func == (lhs: ScrollState, rhs: ScrollState) -> Bool {
        return lhs.cursor == rhs.cursor
            && lhs.actualHeight == rhs.actualHeight
    }
}

public enum ScrollMessage {
    case move(Int)
}

public class ScrollView<Message>: View<Message> {
    var state: ScrollState
    let content: [View<Message>]
    
    public init(_ content: [View<Message>], layoutPolicy: LayoutPolicy = LayoutPolicy(), _ state: ScrollState) {
        self.content = content
        self.state = state
        super.init([], layoutPolicy)
    }
    
    override func measure(availableSize: Size) -> Size {
        let sizes = content.map { $0.measure(availableSize: availableSize) }
        let wantedWidth: Int = sizes.map { $0.width }.sorted(by: >).first!
        let wantedHeight = sizes.map { $0.height }.reduce(0, +)
        let size: Size
        switch layoutPolicy.height {
        case .Exact:
            size = Size(width: min(availableSize.width, wantedWidth), height: min(availableSize.height, wantedHeight))
        case .Flexible:
            size = Size(width: min(availableSize.width, wantedWidth), height: availableSize.height)
        }
        measureStatus = .Measured(size)
        state.actualHeight = wantedHeight
        return size
    }
    
    override func renderTo(buffer: Buffer<Message>, in rect: Rect, events: [ViewEvent<Message>]) {
        state.visibleHeight = rect.height
        
        switch measureStatus {
        case .NotMeasured:
            os_log("Container not measured, skipping")
        case .Measured(let size):
            let tmpBuffer = Buffer<Message>(size: Size(width: size.width, height: state.actualHeight))
            var yOffset = 0
            
            for renderable in content {
                switch renderable.measureStatus {
                case .NotMeasured:
                    os_log("Found unmeasured component, skipping")
                case .Measured(let measuredSize):
                    let renderableRect = Rect(rect.x, yOffset, measuredSize.width, measuredSize.height)
                    renderable.renderTo(buffer: tmpBuffer, in: renderableRect, events: events + self.events)
                    yOffset += renderableRect.height
                }
            }
            
            let visibleRect = Rect(rect.x, state.offset, rect.width, min(rect.height, state.actualHeight))
            let subBuffer = tmpBuffer.subBuffer(rect: visibleRect)
            let drawRect = Rect(rect.x, rect.y, subBuffer.size.width, subBuffer.size.height)
            buffer.replaceRect(drawRect, with: subBuffer)
            
            let visibleCursor = Cursor(state.cursor.x, state.cursor.y + rect.y - state.offset)
            buffer.addCursor(cursor: visibleCursor)
        }
    }
    
    public class func update(_ message: ScrollMessage, _ state: ScrollState) -> ScrollState {
        switch message {
        case .move(let num):
            var newY = state.cursor.y + num
            
            // Handle moving outside container
            if newY >= state.actualHeight {
                newY = state.actualHeight - 1
            } else if newY < 0 {
                newY = 0
            }
            
            // Handle scrolling
            if newY >= state.visibleHeight + state.offset {
                state.offset = (newY + 1) - state.visibleHeight
            } else if newY < state.offset {
                state.offset = newY
            }
            return state.copy(withCursor: state.cursor.copy(withY: newY))
        }
        
    }
    
    public class func initialState() -> ScrollState {
        ScrollState(Cursor(0, 0))
    }
}

private func isGrow(_ layoutRule: LayoutRule) -> Bool {
    if case layoutRule = LayoutRule.Flexible {
        return true
    } else {
        return false
    }
}
