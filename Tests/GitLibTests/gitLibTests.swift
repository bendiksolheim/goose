import XCTest
@testable import GitLib
import Bow

final class changeParseTests: XCTestCase {
    
    func testOneUntrackedFile() {
        let input = "? lol.md"
        let changes = parseChange(input).getOrElse([])
        let expected = [Change(area: Area.Worktree, status: FileStatus.Untracked, file: "lol.md")]
        XCTAssertEqual(changes, expected)
    }
    
    func testOneUnstagedFile() {
        let input = "? lol.md"
        let changes = parseChange(input).getOrElse([])
        let expected = [Change(area: Area.Worktree, status: FileStatus.Untracked, file: "lol.md")]
        XCTAssertEqual(changes, expected)
    }

    static var allTests = [
        ("testOneUntrackedFile", testOneUntrackedFile),
    ]
}
