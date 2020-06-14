import XCTest
@testable import tea

final class ContainerUpdateTests: XCTestCase {
    
    enum Msg {
        case Dummy
    }
    
    func test_move_one_down_when_space_should_only_move_cursor() {
        let state = ScrollState(Cursor(0, 0))
        state.actualHeight = 2
        state.visibleHeight = 2
        let newState = ScrollView<Msg>.update(.move(1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 1))
    }
 
    func test_move_one_up_when_space_should_only_move_cursor() {
        let state = ScrollState(Cursor(0, 1))
        state.actualHeight = 2
        state.visibleHeight = 2
        let newState = ScrollView<Msg>.update(.move(-1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 0))
    }
    
    func test_move_one_down_when_not_space_should_scroll_one_down() {
        let state = ScrollState(Cursor(0, 0))
        state.actualHeight = 2
        state.visibleHeight = 1
        let newState = ScrollView<Msg>.update(.move(1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 1))
        XCTAssertEqual(newState.offset, 1)
    }
    
    func test_move_two_down_when_not_space_should_scroll_two_down() {
        let state = ScrollState(Cursor(0, 0))
        state.actualHeight = 3
        state.visibleHeight = 1
        let newState = ScrollView<Msg>.update(.move(2), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 2))
        XCTAssertEqual(newState.offset, 2)
    }
    
    func test_move_one_down_when_space_two_high_should_not_scroll() {
        let state = ScrollState(Cursor(0, 0))
        state.actualHeight = 3
        state.visibleHeight = 2
        let newState = ScrollView<Msg>.update(.move(1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 1))
        XCTAssertEqual(newState.offset, 0)
    }
    
    func test_move_two_down_when_not_space_two_high_should_scroll() {
        let state = ScrollState(Cursor(0, 0))
        state.actualHeight = 3
        state.visibleHeight = 2
        let newState = ScrollView<Msg>.update(.move(2), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 2))
        XCTAssertEqual(newState.offset, 1)
    }
    
    func test_move_one_up_when_not_space_two_high() {
        let state = ScrollState(Cursor(0, 1))
        state.actualHeight = 2
        state.visibleHeight = 1
        state.offset = 1
        let newState = ScrollView<Msg>.update(.move(-1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 0))
        XCTAssertEqual(newState.offset, 0)
    }
    
    func test_move_two_up_when_space_two_high() {
        let state = ScrollState(Cursor(0, 3))
        state.actualHeight = 4
        state.visibleHeight = 2
        state.offset = 2
        let newState = ScrollView<Msg>.update(.move(-1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 2))
        XCTAssertEqual(newState.offset, 2)
    }
    
    func test_move_one_up_when_not_space_four_high() {
        let state = ScrollState(Cursor(0, 2))
        state.actualHeight = 4
        state.visibleHeight = 2
        state.offset = 2
        let newState = ScrollView<Msg>.update(.move(-1), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 1))
        XCTAssertEqual(newState.offset, 1)
    }
    
    func test_move_two_up_when_not_space_two_high() {
        let state = ScrollState(Cursor(0, 2))
        state.actualHeight = 4
        state.visibleHeight = 2
        state.offset = 2
        let newState = ScrollView<Msg>.update(.move(-2), state)
        XCTAssertEqual(newState.cursor, Cursor(0, 0))
        XCTAssertEqual(newState.offset, 0)
    }
    
    static var allTests = [
        ("move_one_down_when_space_should_only_move_cursor", test_move_one_down_when_space_should_only_move_cursor),
        ("test_move_one_up_when_space_should_only_move_cursor", test_move_one_up_when_space_should_only_move_cursor)
    ]
}
