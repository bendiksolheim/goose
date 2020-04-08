//
//  Section.swift
//  magit
//
//  Created by Bendik Solheim on 04/04/2020.
//

import Foundation
import Ashen
import os.log

enum TitleType {
    case String(String)
    case LabelView(LabelView)
}

class Section<T>: ComponentLayout {
    
    let size: DesiredSize
    
    public init(
        at location: Location = .tl(.zero),
        title: TitleType,
        items: [T],
        itemMapper: (_ item: T) -> Component,
        open: Bool,
        screenSize: Size
    ) {
        
        self.size = DesiredSize(width: screenSize.width, height: items.count + 2)
        super.init()
        
        let titleComponent: Component
        switch title {
        case .String(let stringTitle):
            titleComponent = LabelView(text: Text(stringTitle, [.foreground(.blue)]))
        case .LabelView(let labelView):
            titleComponent = labelView
        }
        
        self.components = [titleComponent] + items.map(itemMapper)
        self.location = location
    }
    
    override public func desiredSize() -> DesiredSize {
        return size
    }
    
    override public func render(to buffer: Buffer, in rect: Rect) {
        var viewX = 0
        var viewY = 0
        var colWidth = 0
        for component in components {
            guard let view = component as? ComponentView else {
                component.render(to: buffer, in: rect)
                continue
            }
            let viewSize = constrain(self: view.desiredSize(), in: rect.size)

            colWidth = max(colWidth, viewSize.width)

            if viewY + viewSize.height > rect.size.height {
                viewX += colWidth
                colWidth = 0
                viewY = 0
            }

            let offset = Point(x: viewX, y: viewY)
            viewY += viewSize.height

            buffer.push(offset: offset, clip: viewSize) {
                view.render(to: buffer, in: Rect(size: viewSize))
            }
        }
    }
}

func constrain(self: DesiredSize, in size: Size) -> Size {
    let width = self.width != nil ? constrainDimension(self: self.width!, in: size, axis: .x) : 0
    let height = self.height != nil ? constrainDimension(self: self.height!, in: size, axis: .y) : 0
    return Size(width: width, height: height)
}

func constrainDimension(self: Ashen.Dimension, in size: Size, axis: Axis) -> Int {
    let max: Int
    switch axis {
    case .x: max = size.width
    case .y: max = size.height
    }

    switch self {
    case let .literal(literal):
        return literal
    case let .calculate(calculate):
        return calculate(size, axis)
    case .max:
        return max
    case let .percent(percent):
        return max * percent / 100
    case let .biggest(values):
        return values.filter({ $0 <= max }).max() ?? 0
    }
}
