import XCTest
@testable import GitLib

final class LogParsingTests: XCTestCase {

    func testParseSimpleLogLineWithGraph() {
        let input = "* 6d10aad08e4d8f83e4d20e6a0bb79b4fecaac1bf\u{200B}6d10aad\u{200B}Bendik Solheim\u{200B}hello@bendik.dev\u{200B}1602446610\u{200B}1602446610\u{200B}0ca64123d16bc5cf5830c0e9c78307fd22316ff3\u{200B}Add function for displaying git command\u{200B}"
        let git = Git(path: ".")
        let commits = parseLog(git: git, input)
        XCTAssertEqual(commits.count, 1)
        if case let .CommitLine(commit) = commits[0] {
            XCTAssertEqual(commit.hash.full, "6d10aad08e4d8f83e4d20e6a0bb79b4fecaac1bf")
            XCTAssertEqual(commit.graph, .some("*"))
        } else {
            XCTFail()
        }
    }

    func testParsingNestedLogLineWithGraph() {
        let input = "| * d9934fc50e95914af6ec2b676c551163ffd43616\u{200B}d9934fc\u{200B}Bendik Solheim\u{200B}hello@bendik.dev\u{200B}1618347118\u{200B}1618347118\u{200B}737d5aa00c1b58c81e93073c7660439f58be2af6\u{200B}Rewrite to Swift terminal library\u{200B}origin/pure-swift, pure-swift"
        let git = Git(path: ".")
        let commits = parseLog(git: git, input)
        XCTAssertEqual(commits.count, 1)
        if case let .CommitLine(commit) = commits[0] {
            XCTAssertEqual(commit.hash.full, "d9934fc50e95914af6ec2b676c551163ffd43616")
            XCTAssertEqual(commit.graph, .some("| *"))
        } else {
            XCTFail()
        }
    }

    func testParsingLogWithoutGraph() {
        let input = "d9934fc50e95914af6ec2b676c551163ffd43616\u{200B}d9934fc\u{200B}Bendik Solheim\u{200B}hello@bendik.dev\u{200B}1618347118\u{200B}1618347118\u{200B}737d5aa00c1b58c81e93073c7660439f58be2af6\u{200B}Rewrite to Swift terminal library\u{200B}origin/pure-swift, pure-swift"
        let git = Git(path: ".")
        let commits = parseLog(git: git, input)
        XCTAssertEqual(commits.count, 1)
        if case let .CommitLine(commit) = commits[0] {
            XCTAssertEqual(commit.hash.full, "d9934fc50e95914af6ec2b676c551163ffd43616")
            XCTAssertEqual(commit.graph, .none())
        } else {
            XCTFail()
        }
    }

    func testParsingMergeLogLine() {
        let input = "*   8d4a750bdcbc9d2aa46229aff1a32eec2ece3737\u{200B}8d4a750\u{200B}Bendik Solheim\u{200B}hello@bendik.dev\u{200B}1618347280\u{200B}1618347280\u{200B}737d5aa00c1b58c81e93073c7660439f58be2af6 d9934fc50e95914af6ec2b676c551163ffd43616\u{200B}Merge pull request #1 from bendiksolheim/pure-swift\u{200B}"
        let git = Git(path: ".")
        let commits = parseLog(git: git, input)
        XCTAssertEqual(commits.count, 1)
        if case let .CommitLine(commit) = commits[0] {
            XCTAssertEqual(commit.hash.full, "8d4a750bdcbc9d2aa46229aff1a32eec2ece3737")
            XCTAssertEqual(commit.graph, .some("*"))
        } else {
            XCTFail()
        }
    }

    func testParsingGraphOnlyLine() {
        let input = "|\\"
        let git = Git(path: ".")
        let commits = parseLog(git: git, input)
        XCTAssertEqual(commits.count, 1)
        if case let .GraphLine(log) = commits[0] {
            XCTAssertEqual(log, "|\\")
        } else {
            XCTFail()
        }
    }
}