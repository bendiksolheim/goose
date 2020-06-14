import XCTest
@testable import tea

final class teaTests: XCTestCase {
    enum Msg {
        case Dummy
    }
    
    func test_rendering_with_one_too_large_container() {
        let screen = Buffer<Msg>(size: Size(width: 1, height: 1))
        let container = ScrollView<Msg>([TextView("A"), TextView("B")], layoutPolicy: LayoutPolicy(), ScrollState(Cursor(0, 0)))
        let window = Window(content: [container])
        window.measureIn(screen)
        window.renderTo(screen)
        XCTAssertEqual(screen.cell(cursor: Cursor(0, 0))?.content.char, "A")
    }
    
    func test_rendering_with_two_too_large_containers() {
        let screen = Buffer<Msg>(size: Size(width: 1, height: 2))
        let containerOne = ScrollView<Msg>([TextView("A"), TextView("B")], layoutPolicy: LayoutPolicy(height: LayoutRule.Flexible), ScrollState(Cursor(0, 0)))
        let containerTwo = ScrollView<Msg>([TextView("C"), TextView("D")], layoutPolicy: LayoutPolicy(height: LayoutRule.Flexible), ScrollState(Cursor(0, 0)))
        let window = Window(content: [containerOne, containerTwo])
        window.measureIn(screen)
        window.renderTo(screen)
        XCTAssertEqual(containerOne.measureStatus, .Measured(Size(width: 1, height: 1)))
        XCTAssertEqual(containerTwo.measureStatus, .Measured(Size(width: 1, height: 1)))
        XCTAssertEqual(screen.cell(cursor: Cursor(0, 0))?.content.char, "A")
        XCTAssertEqual(screen.cell(cursor: Cursor(0, 1))?.content.char, "C")
    }

    static var allTests = [
        ("test_rendering_with_one_too_large_container", test_rendering_with_one_too_large_container),
        ("test_rendering_with_two_too_large_containers", test_rendering_with_two_too_large_containers)
    ]
}
