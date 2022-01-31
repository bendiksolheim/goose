public struct FlexStyle {
    let direction: FlexDirection
    let grow: Float
    let shrink: Float
    
    public init(direction: FlexDirection = .Row, grow: Float = 1, shrink: Float = 1) {
        self.direction = direction
        self.grow = grow
        self.shrink = shrink
    }
}
