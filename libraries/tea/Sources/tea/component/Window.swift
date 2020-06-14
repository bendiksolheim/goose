import Foundation
import os.log

public struct Window<Message> {
    let content: [View<Message>]
    
    public init(content: [View<Message>]) {
        self.content = content
    }
}

extension Window {
    func measureIn(_ buffer: Buffer<Message>) {
        let availableSize = buffer.size
        let renderables = content.map { ($0, $0.measure(availableSize: availableSize)) }
        
        let wantedHeight = renderables.map { $0.1.height }.reduce(0, +)
        let flexers = renderables.filter { isFlexible($0.0.layoutPolicy.height) }
        var flexerCount = flexers.count
        if wantedHeight > availableSize.height && flexerCount > 0 {
            // Wanted size is too high
            var overshot = wantedHeight - availableSize.height
            
            renderables.forEach { (renderable, renderableSize) in
                if isFlexible(renderable.layoutPolicy.height) {
                    let heightDiff = Int(floor(Double(overshot) / Double(flexerCount)))
                    let newHeight = renderableSize.height - heightDiff
                    renderable.measure(availableSize: Size(width: availableSize.width, height: newHeight))
                    overshot -= heightDiff
                    flexerCount -= 1
                }
            }
        } else if wantedHeight < availableSize.height && flexerCount > 0 {
            // We have space left, lets spread it out
            let spaceLeft = buffer.size.height - wantedHeight
            
            renderables.forEach { (renderable, renderableSize) in
                if isFlexible(renderable.layoutPolicy.height) {
                    let newHeight = renderableSize.height + spaceLeft / flexerCount
                    renderable.measure(availableSize: Size(width: availableSize.width, height: newHeight))
                }
            }
        }
    }
    
    func renderTo(_ buffer: Buffer<Message>) {
        var yOffset = 0
        for renderable in content {
            switch renderable.measureStatus {
            case .NotMeasured:
                os_log("Found unmeasured component, skipping")
            case .Measured(let measuredSize):
                let rect = Rect(0, yOffset, measuredSize.width, measuredSize.height)
                renderable.renderTo(buffer: buffer, in: rect, events: [])
                yOffset += rect.height
            }
        }
        /*let height = buffer.size.height
        let growers = content.map { $0.layoutPolicy.height }.filter(isFlexible)
        let leftOverHeight = max(height - content.map { $0.measure().height }.reduce(0, +), 0)
        let splitHeight: Int = leftOverHeight / max(growers.count, 1)
        
        var yOffset = 0
        for renderable in content {
            let size = renderable.measure()
            let layoutPolicy = renderable.layoutPolicy
            let rect: Rect
            if isFlexible(layoutPolicy.height) {
                rect = Rect(0, yOffset, size.width, size.height + splitHeight)
            } else {
                rect = Rect(0, yOffset, size.width, size.height)
            }
            renderable.renderTo(buffer: buffer, in: rect)
            yOffset += rect.height
        }*/
    }
}

private func isFlexible(_ layoutRule: LayoutRule) -> Bool {
    if case layoutRule = LayoutRule.Flexible {
        return true
    } else {
        return false
    }
}
