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
        do {
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
        } catch {
            os_log("what")
        }
    }
}

public struct GitHunk {
    public let lines: [String]
    
    init(_ lines: [String]) {
        self.lines = lines
    }
}

public struct GitFile {
    public let source: String
    public let hunks: [GitHunk]
    
    init(_ source: String, _ hunks: [GitHunk]) {
        self.source = source
        self.hunks = hunks
    }
}

public struct GitDiff {
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
let aLine = string("---") <* takeLine
let bLine = string("+++") <* takeLine
let fileHeader = diff <* index <* aLine <* bLine
let file = makeFile <^> fileHeader <*> hunks
let parseDiff = file.many.map(GitDiff.init)
