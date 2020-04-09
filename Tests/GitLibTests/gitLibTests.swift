import XCTest
@testable import GitLib
import Bow

final class changeParseTests: XCTestCase {
    
    func testOneUntrackedFile() {
        let input = "? file.md"
        let changes = parseChange(input).getOrElse([])
        let expected = [Change(area: .Worktree, status: .Untracked, file: "file.md")]
        XCTAssertEqual(changes, expected)
    }
    
    func testOneUnstagedFile() {
        let input = "1 .M N... 100644 100644 100644 d057de2786136730ee81a024345f1181a084138a d057de2786136730ee81a024345f1181a084138a file.md"
        let changes = parseChange(input).getOrElse([])
        let expected = [Change(area: .Worktree, status: .Modified, file: "file.md")]
        XCTAssertEqual(changes, expected)
    }
    
    func testOneStagedFile() {
        let input = "1 M. N... 100644 100644 100644 d057de2786136730ee81a024345f1181a084138a f808ed536bda8d492749f2e4d12bc4ce74284e7a file.md"
        let changes = parseChange(input).getOrElse([])
        let expected = [Change(area: .Index, status: .Modified, file: "file.md")]
        XCTAssertEqual(changes, expected)
    }
    
    func testNewFileStagedThenDeletedInWorktree() {
        let input = "1 AD N... 000000 100644 000000 0000000000000000000000000000000000000000 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 file.md"
        let changes = parseChange(input).getOrElse([])
        let expected = [Change(area: .Index, status: .Added, file: "file.md"), Change(area: .Worktree, status: .Deleted, file: "file.md")]
        XCTAssertEqual(changes, expected)
    }

    static var allTests = [
        ("testOneUntrackedFile", testOneUntrackedFile),
    ]
}
