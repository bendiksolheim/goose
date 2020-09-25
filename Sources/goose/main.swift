import Foundation
import ArgumentParser
import tea

func teaRun(
    _ initialize: () -> (Model, Cmd<Message>),
    _ render: @escaping (Model) -> Window<Message>,
    _ update: @escaping (Message, Model) -> (Model, Cmd<Message>),
    _ subscriptions: [Sub<Message>]) {
    run(initialize: initialize, render: render, update: update, subscriptions: subscriptions)
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
