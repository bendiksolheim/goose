import Foundation
import SwiftParsec
import Bow
import os.log

public struct DiffFiles {
    public static func command() -> GitCommand {
        GitCommand(
            arguments: ["diff-files", "--patch", "--no-color"]
        )
    }
    
    public static func parse(_ input: String) -> Bow.Either<Error, GitDiff> {
        os_log("test")
        let diff = parseDiff.runSafe(userState: (), sourceName: "", input: input)
        switch diff {
        case .left(let error):
            os_log("%{public}@", input)
            os_log("%{public}@", error.description)
            return Bow.Either.left(error)
        case .right(let diff):
            os_log("%{public}@", "\(diff)")
            return Bow.Either.right(diff)
        }
    }
}

public enum GitAnnotation: Equatable {
    case Summary
    case Added
    case Removed
    case Context
}

public struct GitHunkLine: Equatable {
    public let annotation: GitAnnotation
    public let content: String
    
    init(_ line: String) {
        let first = line[0]
        switch first {
        case "@":
            self.annotation = .Summary
        case "+":
            self.annotation = .Added
        case "-":
            self.annotation = .Removed
        default:
            self.annotation = .Context
        }
        self.content = line
    }
}

public struct GitHunk: Equatable {
    public let lines: [GitHunkLine]
    
    init(_ lines: [String]) {
        self.lines = lines.map(GitHunkLine.init)
    }
}

public struct GitFile: Equatable {
    public let source: String
    public let hunks: [GitHunk]
    
    init(_ source: String, _ hunks: [GitHunk]) {
        self.source = source
        self.hunks = hunks
    }
}

public struct GitDiff: Equatable {
    public let files: [GitFile]
    
    init(_ files: [GitFile]) {
        self.files = files
    }
}


func makeLine(_ a: String) -> (String) -> String {
    { rest in a + rest }
}
func makeHunk(_ start: String) -> ([String]) -> GitHunk {
    { annotatedLines in GitHunk(["@@" + start] + annotatedLines)}
}
func makeFile(_ source: String) -> ([GitHunk]) -> GitFile {
    { hunks in GitFile(source, hunks) }
}

let character = StringParser.character
let string = StringParser.string
let anyCharacter = StringParser.anyCharacter
let newLine = StringParser.newLine
let decimalDigit = StringParser.decimalDigit
let endOfLine = StringParser.endOfLine
let endOfFile = StringParser.eof

let anyString = anyCharacter.many.stringValue
let eof = endOfFile.map { " ".first! } // Need to force type to be GenericParser<Self.StreamType, Self.UserState, Character>
let end = endOfLine <|> eof
let takeLine = anyCharacter.manyTill(end).stringValue

let annotation = (character("+") <|> character("-") <|> character(" ")).stringValue
let annotatedLine = makeLine <^> annotation <*> takeLine
let hunkStart = string("@@") *> takeLine
let hunk = makeHunk <^> hunkStart <*> annotatedLine.many
let hunks = hunk.many
let path = anyCharacter *> character("/") *> StringParser.noneOf(" ").many.stringValue
let diff = string("diff --git ") *> path <* takeLine
let index = string("index") <* takeLine
let fileStatus =
    (string("deleted file mode") <* takeLine)
        <|> (string("new file mode") <* takeLine)
        <|> (string("rename to") <* takeLine)
let statusAndindex = (fileStatus <* index) <|> index
let aLine = string("---") <* takeLine
let bLine = string("+++") <* takeLine
let fileHeader = diff <* statusAndindex <* aLine <* bLine
let file = makeFile <^> fileHeader <*> hunks
let parseDiff = file.many.map(GitDiff.init)
