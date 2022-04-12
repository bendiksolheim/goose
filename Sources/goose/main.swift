import Foundation
import ArgumentParser
import Tea
import Slowbox

func teaRun(
    _ initialize: @escaping (TerminalInfo) -> () -> (Model, Cmd<Message>),
    _ render: @escaping (Model, Size) -> ViewModel<Message, ViewData>,
    _ update: @escaping (Message, Model, ViewModel<Message, ViewData>) -> (Model, Cmd<Message>),
    _ subscriptions: [Sub<Message>]) {
    run { terminalInfo in
        App(initialize: initialize(terminalInfo), render: render, update: update, subscriptions: subscriptions)
    }
}

struct Goose: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Enabled debug logging")
    var debug: Bool = false
    
    mutating func run() throws {
        Logger.debug = debug
        if let basePath = locateGitDir() {
            Logger.log("Starting goose")
            teaRun(initialize(basePath: basePath), render, update, subscriptions)
        } else {
            print("\(FileManager.default.currentDirectoryPath) is not inside a git directory")
        }
    }
}

Goose.main()
