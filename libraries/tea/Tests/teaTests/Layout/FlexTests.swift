import XCTest
@testable import tea

final class FlexTests: XCTestCase {
    func testEmptyChildren() throws {
        let parent = Layout.calculate(node: Container(FlexStyle(), []), width: 100, height: 100)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 0, height: 0))
    }
    
    func testSingleChild() {
        let parent = Layout.calculate(node: Container(FlexStyle(), [Content("Hello")]), width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 10, height: 1))
    }
    
    func testMultipleChildrenOnRow() {
        let parent = Layout.calculate(node: Container(FlexStyle(), [Content("Hello"), Content("There")]), width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 10, height: 1))
    }
    
    func testMultipleChildrenOnColumn() {
        let parent = Layout.calculate(node: Container(FlexStyle(direction: .Column), [Content("Hello"), Content("There")]), width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 5, height: 10))
    }
    
    func testSingeChildWithoutGrow() {
        let style = FlexStyle(grow: 0)
        let container = Container(FlexStyle(grow: 0), [Content("Hello", style)])
        let parent = Layout.calculate(node: container, width: 10, height: 10)
        XCTAssertEqual(parent.rect, Rectangle(x: 0, y: 0, width: 5, height: 1))
    }
    
    func testPlacementOfTwoContentsInColumn() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [Content("Hello"), Content("There")])
        let parent = Layout.calculate(node: container, width: 5, height: 2)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 1),
            Rectangle(x: 0, y: 1, width: 5, height: 1)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testPlacementOfTwoContentsInColumnFirstGrowing() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [
            Content("Hello"),
            Content("There", FlexStyle(grow: 0))
        ])
        let parent = Layout.calculate(node: container, width: 5, height: 3)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 2),
            Rectangle(x: 0, y: 2, width: 5, height: 1)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testPlacementOfTwoContentsInColumnBothGrowing() {
        let style = FlexStyle(direction: .Column)
        let container = Container(style, [
            Content("Hello"),
            Content("There")
        ])
        let parent = Layout.calculate(node: container, width: 5, height: 4)
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
            Content("Hello\nThere"),
            Content("I am\nHere")
        ])
        let parent = Layout.calculate(node: container, width: 5, height: 2)
        let placements = parent.children()!.map { $0.rect }
        let expectedPlacements = [
            Rectangle(x: 0, y: 0, width: 5, height: 1),
            Rectangle(x: 0, y: 1, width: 4, height: 1)
        ]
        XCTAssertEqual(placements, expectedPlacements)
    }
    
    func testNestedContainerWithContent() {
        let container = Container([
            Container([
                Content("Hello, world!")
            ])
        ])
        let parent = Layout.calculate(node: container, width: 13, height: 1)
        let innerContainerPlacement = parent.children()!.map { $0.rect }
        let textPlacement = parent.children()!.flatMap { $0.children()!.map { $0.rect } }
        XCTAssertEqual(innerContainerPlacement, [Rectangle(x: 0, y: 0, width: 13, height: 1)])
        XCTAssertEqual(textPlacement, [Rectangle(x: 0, y: 0, width: 13, height: 1)])
    }
    
    func testUnnecessarilyNestedContainersWithContent() {
        let container = Container([
            Container([
                Container([
                    Content("Hello, world!")
                ])
            ])
        ])
        let parent = Layout.calculate(node: container, width: 13, height: 1)
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
