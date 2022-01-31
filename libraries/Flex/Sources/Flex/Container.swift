import Foundation
import Darwin

public protocol Node {
    var rect: Rectangle { get }
    var style: FlexStyle { get }
    
    func withWidth(_ width: Int) -> Node
    func withHeight(_ height: Int) -> Node
    func withX(_ x: Int) -> Node
    func withY(_ y: Int) -> Node
    func measureMainSize() -> Node
    func measureCrossSize() -> Node
    func constrainTo(_ width: Int, _ height: Int) -> Node
    func mainSize(for: FlexDirection) -> Int
    func crossSize(for: FlexDirection) -> Int
    func placeAt(x: Int, y: Int) -> Node
    func children() -> [Node]?
}

public struct Container: Node {
    let content: [Node]
    public let style: FlexStyle
    public let rect: Rectangle
    
    public init(_ style: FlexStyle, _ children: [Node]) {
        self.style = style
        self.content = children
        self.rect = Rectangle.empty()
    }
    
    public init(_ children: [Node]) {
        self.style = FlexStyle()
        self.content = children
        self.rect = Rectangle.empty()
    }
    
    private init(_ children: [Node], _ style: FlexStyle, _ rect: Rectangle) {
        self.style = style
        self.content = children
        self.rect = rect
    }
    
    public func measureMainSize() -> Node {
        let measuredChildren = content.map { $0.measureMainSize() }
        let measuredMainSize = measuredChildren.reduce(0, { $0 + $1.mainSize(for: style.direction)})
        switch style.direction {
        case .Row:
            return Container(measuredChildren, style, rect.withWidth(measuredMainSize))
        case .Column:
            return Container(measuredChildren, style, rect.withHeight(measuredMainSize))
        }
    }
    
    public func measureCrossSize() -> Node {
        let measuredChildren = content.map { $0.measureCrossSize() }
        let measuredCrossSize = measuredChildren.map { $0.crossSize(for: style.direction) }.max() ?? 0
        switch style.direction {
        case .Row:
            return Container(measuredChildren, style, rect.withHeight(measuredCrossSize))
        case .Column:
            return Container(measuredChildren, style, rect.withWidth(measuredCrossSize))
        }
    }
    
    public func constrainTo(_ _width: Int, _ _height: Int) -> Node {
        switch style.direction {
        case .Row:
            return constrainRowTo(_width, _height)
        case .Column:
            return constrainColumnTo(_width, _height)
        }
    }
    
    func constrainRowTo(_ width: Int, _ height: Int) -> Node {
        if self.rect.width < width {
            // view too small
            let remaining = width - self.rect.width
            let grows = content.map { $0.style.grow }
            let totalGrow = grows.reduce(0) { $0 + $1 }
            let oneGrow = totalGrow == 0 ? 0 : (Float(remaining) / Float(totalGrow))
            let children = content.map { $0.withWidth($0.rect.width + Int(round(Float($0.style.grow) * oneGrow)))}
            let newWidth = children.map { $0.rect.width }.reduce(0, +)
            return self.withChildren(children).withWidth(newWidth)
        } else if self.rect.width > width {
            // view too large
            let scaledShrinkFactors = content.map { $0.style.shrink * Float($0.rect.width) }
            let totalScaledShrinkFactor = scaledShrinkFactors.reduce(0.0) { $0 + $1 }
            let children = content.map { $0.withWidth(Int(round($0.style.shrink * Float($0.rect.width) / totalScaledShrinkFactor))) }
            let newWidth = children.map { $0.rect.width }.reduce(0, +)
            return self.withChildren(children).withWidth(newWidth)
        }
        
        return self
    }
    
    func constrainColumnTo(_ width: Int, _ height: Int) -> Node {
        if self.rect.height < height {
            let remaining = height - self.rect.height
            let grows = content.map { $0.style.grow }
            let totalGrow = grows.reduce(0) { $0 + $1 }
            let oneGrow = Float(remaining) / Float(totalGrow)
            let children = content.map { $0.withHeight($0.rect.height + Int(round(Float($0.style.grow) * oneGrow)))}
            let newHeight = children.map { $0.rect.height }.reduce(0, +)
            return self.withChildren(children).withHeight(newHeight)
        } else if self.rect.height > height {
            // view too large
            let scaledShrinkFactors = content.map { $0.style.shrink * Float($0.rect.height) }
            let totalScaledShrinkFactor = scaledShrinkFactors.reduce(0.0) { $0 + $1 }
            let children = content.map { $0.withHeight(Int(round($0.style.shrink * Float($0.rect.height) / totalScaledShrinkFactor))) }
            let newHeight = children.map { $0.rect.height }.reduce(0, +)
            return self.withChildren(children).withHeight(newHeight)
        }
        
        return self
    }
    
    public func placeAt(x: Int, y: Int) -> Node {
        switch style.direction {
        case .Row:
            return placeAtRow(x: x, y: y)
        case .Column:
            return placeAtColumn(x: x, y: y)
        }
    }
    
    func placeAtRow(x: Int, y: Int) -> Node {
        var nextX = 0
        let placedChildren: [Node] = content.map {
            let placedChild: Node = $0.withX(nextX).withY(y)
            nextX = placedChild.rect.x + placedChild.rect.width
            return placedChild
        }
        
        return withChildren(placedChildren)
    }
    
    func placeAtColumn(x: Int, y: Int) -> Node {
        var nextY = 0
        let placedChildren: [Node] = content.map {
            let placedChild = $0.withX(x).withY(nextY)
            nextY = placedChild.rect.y + placedChild.rect.height
            return placedChild
        }
        
        return withChildren(placedChildren)
    }
    
    public func withWidth(_ width: Int) -> Node {
        return Container(self.content, self.style, rect.withWidth(width))
    }
    
    public func withHeight(_ height: Int) -> Node {
        return Container(self.content, self.style, rect.withHeight(height))
    }
    
    public func withX(_ x: Int) -> Node {
        return Container(self.content, self.style, rect.withX(x))
    }
    
    public func withY(_ y: Int) -> Node {
        return Container(self.content, self.style, rect.withY(y))
    }
    
    public func withChildren(_ children: [Node]) -> Node {
        return Container(children, self.style, self.rect)
    }
    
    public func mainSize(for direction: FlexDirection) -> Int {
        return content.reduce(0) { $0 + $1.mainSize(for: direction) }
    }
    
    public func crossSize(for direction: FlexDirection) -> Int {
        return content.reduce(0) { $0 + $1.crossSize(for: direction) }
    }
    
    public func children() -> [Node]? {
        return content
    }
}

public struct Text: Node {
    let text: String
    public let style: FlexStyle
    public let rect: Rectangle
    
    public init(_ text: String, _ style: FlexStyle = FlexStyle()) {
        self.text = text
        self.style = style
        let lines = text.split(separator: "\n")
        let width = lines.map { $0.count }.max() ?? 0
        let height = lines.count
        self.rect = Rectangle(x: 0, y: 0, width: width, height: height)
    }
    
    private init(_ text: Text, _ rect: Rectangle) {
        self.text = text.text
        self.style = text.style
        self.rect = rect
    }
    
    public func placeAt(x: Int, y: Int) -> Node {
        return Text(self, rect.withX(x).withY(y))
    }
    
    public func withWidth(_ width: Int) -> Node {
        return Text(self, rect.withWidth(width))
    }
    
    public func withHeight(_ height: Int) -> Node {
        return Text(self, rect.withHeight(height))
    }
    
    public func withX(_ x: Int) -> Node {
        return Text(self, rect.withX(x))
    }
    
    public func withY(_ y: Int) -> Node {
        return Text(self, rect.withY(y))
    }
    
    public func measureMainSize() -> Node {
        return self
    }
    
    public func measureCrossSize() -> Node {
        return self
    }
    
    public func constrainTo(_ width: Int, _ height: Int) -> Node {
        return withWidth(width).withHeight(height)
    }
    
    public func mainSize(for direction: FlexDirection) -> Int {
        switch direction {
        case .Row:
            return rect.width
        case .Column:
            return rect.height
        }
    }
    
    public func crossSize(for direction: FlexDirection) -> Int {
        switch direction {
        case .Row:
            return rect.height
        case .Column:
            return rect.width
        }
    }
    
    public func children() -> [Node]? {
        return nil
    }
}
