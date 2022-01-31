public struct Flex {
    static func layout(node: Container, width: Int, height: Int) -> Node {
        return node
            .measureMainSize()
            .measureCrossSize()
            .constrainTo(width, height)
            .placeAt(x: 0, y: 0)
    }
}
