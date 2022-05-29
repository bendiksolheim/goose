import Foundation
import ArgumentParser
import Tea
import Slowbox

////func teaRun(
//        _ initialize: @escaping () -> (Model, Cmd<Message>),
//        _ render: @escaping (Model, Size) -> ViewModel<Message, ViewData>,
//        _ update: @escaping (Message, Model, ViewModel<Message, ViewData>) -> (Model, Cmd<Message>),
//        _ update: @escaping (Message, Model) -> (Model, Cmd<Message>),
//        _ subscriptions: [Sub<Message>]) {
//    var result: QuitResult = .Success(nil)
//    repeat {
//        result = run(App(initialize: initialize, render: render, update: update, subscriptions: subscriptions))
//        result = run { terminalInfo in
//            App(initialize: initialize, render: render, update: update, subscriptions: subscriptions)
//        }
//    } while evaluateResult(result)
//}

struct Goose: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Enabled debug logging")
    var debug: Bool = false

    mutating func run() throws {
        Logger.debug = debug
        if let basePath = locateGitDir() {
            Logger.log("Starting goose")
            var result: QuitResult = .Success(nil)
            repeat {
                result = application(App(initialize: initialize(basePath: basePath), render: render, update: update, subscriptions: subscriptions))
            } while evaluateResult(result)
//            teaRun(initialize(basePath: basePath), render, update, subscriptions)
        } else {
            print("\(FileManager.default.currentDirectoryPath) is not inside a git directory")
        }
    }
}

func evaluateResult(_ result: QuitResult) -> Bool {
    switch (result) {
    case let .Success(msg):
        if let msg = msg {
            if msg == "commit" {
                let res = commit()
                return evaluateProcessResult(res)
            } else if msg == "amend" {
                let res = commit(amend: true)
                return evaluateProcessResult(res)
            } else if msg.starts(with: "view:") {
                let file = String(msg[5])
                let res = view(file: file)
                return evaluateProcessResult(res)
            }

            return false
        } else {
            return false
        }
    case .Failure:
        print("Error from TEA")
        return false
    }
}

func evaluateProcessResult(_ result: ProcessResult) -> Bool {
    switch result {
    case .Success:
        return true
    case let .Failure(msg):
        print(msg)
        return false
    }
}

Goose.main()
