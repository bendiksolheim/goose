import Foundation

public enum LayoutRule: Equatable {
    case Flexible
    case Exact
}

public struct LayoutPolicy: Equatable {
    let width: LayoutRule
    let height: LayoutRule

    public init(width: LayoutRule = .Exact, height: LayoutRule = .Exact) {
        self.width = width
        self.height = height
    }
}
