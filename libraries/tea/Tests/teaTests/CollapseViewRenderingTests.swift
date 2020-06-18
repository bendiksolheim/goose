@testable import tea
import XCTest

final class CollapseViewRenderingTests: XCTestCase {
    enum Msg {
        case Dummy
    }

    func test_measuring_1_times_1_uncollapsed_view() {
        let textView = TextView<Msg>("a")
        let view = CollapseView<Msg>(content: [textView], open: true)
        let measured = view.measure(availableSize: Size(width: 1, height: 1))
        XCTAssertEqual(measured, Size(width: 1, height: 1))
        XCTAssertEqual(textView.measureStatus, .Measured(Size(width: 1, height: 1)))
    }

    func test_rendering_single_line_uncollapsed_view() {
        let view = CollapseView<Msg>(content: [TextView("a")], open: true)
        let buffer = Buffer<Msg>(size: Size(width: 1, height: 1))
        let window = Window(content: [view])
        window.measureIn(buffer)
        window.renderTo(buffer)
        XCTAssertEqual(buffer.cell(cursor: Cursor(0, 0))?.content.char, "a")
    }

    static var allTests = [
        ("test_rendering_single_line_uncollapsed_view", test_rendering_single_line_uncollapsed_view),
    ]
}
