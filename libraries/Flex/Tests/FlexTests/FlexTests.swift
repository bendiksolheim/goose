import XCTest
@testable import Flex

final class FlexTests: XCTestCase {
    func testEmptyChildren() throws {
        let parent = Flex.layout(node: Container(FlexStyle(), []), width: 100, height: 100)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 0, height: 0))
    }
    
    func testSingleChild() {
        let parent = Flex.layout(node: Container(FlexStyle(), [Text("Hello")]), width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 10, height: 1))
    }
    
    func testMultipleChildrenOnRow() {
        let parent = Flex.layout(node: Container(FlexStyle(), [Text("Hello"), Text("There")]), width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 10, height: 1))
    }
    
    func testMultipleChildrenOnColumn() {
        let parent = Flex.layout(node: Container(FlexStyle(direction: .Column), [Text("Hello"), Text("There")]), width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 5, height: 10))
    }
    
    func testSingeChildWithoutGrow() {
        let style = FlexStyle(grow: 0)
        let container = Container(FlexStyle(grow: 0), [Text("Hello", style)])
        let parent = Flex.layout(node: container, width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 5, height: 1))
    }
    
    func testPlacementOfTwoTextsInColumn() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [Text("Hello"), Text("There")])
        let parent = Flex.layout(node: container, width: 5, height: 2)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 1),
            Rectangle(x: 0, y: 1, width: 5, height: 1)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testPlacementOfTwoTextsInColumnFirstGrowing() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [
            Text("Hello"),
            Text("There", FlexStyle(grow: 0))
        ])
        let parent = Flex.layout(node: container, width: 5, height: 3)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 2),
            Rectangle(x: 0, y: 2, width: 5, height: 1)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testPlacementOfTwoTextsInColumnBothGrowing() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [
            Text("Hello"),
            Text("There")
        ])
        let parent = Flex.layout(node: container, width: 5, height: 4)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 2),
            Rectangle(x: 0, y: 2, width: 5, height: 2)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testTwoTooLargeContainersWithShrink() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [
            Text("Hello\nThere"),
            Text("I am\nHere")
        ])
        let parent = Flex.layout(node: container, width: 5, height: 2)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 1),
            Rectangle(x: 0, y: 1, width: 4, height: 1)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testNestedContainerWithText() {
        let container = Container([
            Container([
                Text("Hello, world!")
            ])
        ])
        let parent = Flex.layout(node: container, width: 13, height: 1)
        let innerContainerPlacement = parent.children()!.map { $0.rect }
        let textPlacement = parent.children()!.flatMap { $0.children()!.map { $0.rect } }
        XCTAssertEqual(innerContainerPlacement, [Rectangle(x: 0, y: 0, width: 13, height: 1)])
        XCTAssertEqual(textPlacement, [Rectangle(x: 0, y: 0, width: 13, height: 1)])
    }
    
    func testUnnecessarilyNestedContainersWithText() {
        let container = Container([
            Container([
                Container([
                    Text("Hello, world!")
                ])
            ])
        ])
        let parent = Flex.layout(node: container, width: 13, height: 1)
        let c1 = parent.rect
        let c2 = parent.children()!.map { $0.rect }[0]
        let c3 = parent.children()!.flatMap { $0.children()!.map { $0.rect }}[0]
        let t = parent.children()!.flatMap { $0.children()!.flatMap { $0.children()!.map { $0.rect }}}[0]
        let expectedRect = Rectangle(x: 0, y: 0, width: 13, height: 1)
        XCTAssertEqual(c1, expectedRect)
        XCTAssertEqual(c2, expectedRect)
        XCTAssertEqual(c3, expectedRect)
        XCTAssertEqual(t, expectedRect)
    }
}
