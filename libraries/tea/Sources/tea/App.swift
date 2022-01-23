import Darwin
import Foundation
import os.log
import ReactiveSwift
import Slowbox

public enum Sub<Message> {
    case Keyboard((KeyEvent) -> Message)
    case Cursor((Cursor) -> Message)
    case TerminalSize((Size) -> Message)
    case None
}

public struct App<Model: Equatable, Message, Meta> {
    public let initialize: () -> (Model, Cmd<Message>)
    public let render: (Model, Size) -> ViewModel<Message, Meta>
    public let update: (Message, Model, ViewModel<Message, Meta>) -> (Model, Cmd<Message>)
    public let subscriptions: [Sub<Message>]
    
    public init(initialize: @escaping () -> (Model, Cmd<Message>),
                  render: @escaping (Model, Size) -> ViewModel<Message, Meta>,
                  update: @escaping (Message, Model, ViewModel<Message, Meta>) -> (Model, Cmd<Message>),
                  subscriptions: [Sub<Message>]) {
        self.initialize = initialize
        self.render = render
        self.update = update
        self.subscriptions = subscriptions
    }
}

public struct TerminalInfo {
    public let cursor: Cursor
    public let size: Size
}

public func run<Model: Equatable, Message, Meta>(initFunc: (TerminalInfo) -> App<Model, Message, Meta>) {
    let terminal = Slowbox(io: TTY(), screen: .Alternate)
    let app = initFunc(TerminalInfo(cursor: terminal.cursor, size: terminal.terminalSize()))
    runApp(terminal, app)
}

func render<Message, Data>(_ view: ViewModel<Message, Data>, _ terminal: Slowbox) {
    view.view.enumerated().forEach { row in
        if let content = row.element {
            content.content.terminalContent().enumerated().forEach { column in
                terminal.put(x: column.offset, y: row.offset, cell: Cell(column.element.1, formatting: column.element.0))
            }
        }
    }
    terminal.present()
    terminal.clearBuffer()
}

func runApp<Model: Equatable, Message, Meta>(
    _ aTerminal: Slowbox,
    _ app: App<Model, Message, Meta>
) {
    let termQueue = DispatchQueue(label: "term.queue", qos: .background)
    let taskQueue = DispatchQueue(label: "task.queue", qos: .userInitiated)

    var terminal = aTerminal
    var polling = true

    let (initialModel, initialCommand) = app.initialize()
    var model = initialModel
    var viewModel = measure("Initial render") { app.render(model, terminal.terminalSize()) }
    render(viewModel, terminal)

    let keyboardSubscription = getKeyboardSubscription(subscriptions: app.subscriptions)
    let terminalSizeSubscription = getTerminalResizeSubscription(subscriptions: app.subscriptions)
    let cursorSubscription = getCursorSubscription(subscriptions: app.subscriptions)

    let (messageConsumer, messageProducer) = Signal<Message, Never>.pipe()
    let (commandConsumer, commandProducer) = Signal<Cmd<Message>, Never>.pipe()

    func startEventPolling() {
        termQueue.async {
            while polling {
                if let event = terminal.poll() {
                    switch event {
                    case let .Key(key):
                        // special case Ctrl-C to ensure we can always quit programs
                        if key == .CtrlC {
                            polling = false
                            messageProducer.sendCompleted()
                            commandProducer.sendCompleted()
                        } else if viewModel.view.indices.contains(terminal.cursor.y) {
                            let cursor = terminal.cursor
                            let line = viewModel.view[cursor.y]
                            var swallowed = false
                            line?.events.forEach { evChar, message in
                                if evChar == key {
                                    swallowed = true
                                    async { messageProducer.send(value: message) }
                                }
                            }
                            if !swallowed {
                                if let msg = keyboardSubscription?(key) {
                                    async {
                                        messageProducer.send(value: msg)
                                    }
                                }
                            }
                        } else {
                            if let msg = keyboardSubscription?(key) {
                                async {
                                    messageProducer.send(value: msg)
                                }
                            }
                        }
                    case let .Resize(size):
                        viewModel = measure("Resize render") { app.render(model, terminal.terminalSize()) }
                        async {
                            render(viewModel, terminal)
                            if let msg = terminalSizeSubscription?(size) {
                                messageProducer.send(value: msg)
                            }
                        }
                    }
                }
            }
        }
    }

    messageConsumer.observeValues { message in
        let (updatedModel, command) = app.update(message, model, viewModel)
        let modelChanged = !(updatedModel == model)
        model = updatedModel
        async { commandProducer.send(value: command) }
        if modelChanged {
            viewModel = measure("Msg render") { app.render(model, terminal.terminalSize()) }
            async {
                render(viewModel, terminal)
            }
        }
    }

    commandConsumer.observeValues { command in
        switch command.cmd {
        case .None:
            break

        case let .Command(message):
            async { messageProducer.send(value: message) }

        case let .Commands(commands):
            for command in commands {
                async { commandProducer.send(value: command) }
            }

        case let .Task(task):
            taskQueue.async {
                messageProducer.send(value: task())
            }
            
        case let .AsyncTask(delay, task):
            taskQueue.asyncAfter(deadline: .now() + delay) {
                messageProducer.send(value: task())
            }

        case let .Process(process):
            polling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                terminal.restore()
                let message = process()
                polling = true

                async {
                    terminal = Slowbox(io: TTY(), screen: .Alternate)
                    viewModel = measure("Process render") { app.render(model, terminal.terminalSize()) }
                    render(viewModel, terminal)
                    startEventPolling()
                }

                async { messageProducer.send(value: message) }
            }

        case .Quit:
            messageProducer.sendCompleted()
            commandProducer.sendCompleted()
            
        case let .Terminal(terminalCommand):
            switch terminalCommand {
            case let .MoveCursor(xDelta, yDelta):
                let currentCursor = terminal.cursor
                terminal.moveCursor(currentCursor.x + xDelta, currentCursor.y + yDelta)
                if let msg = cursorSubscription?(terminal.cursor) {
                    messageProducer.send(value: msg)
                }
            }
        }
    }

    async { commandProducer.send(value: initialCommand) }
    startEventPolling()

    let runLoop = CFRunLoopGetCurrent()
    messageConsumer.observeCompleted {
        CFRunLoopStop(runLoop)
    }
    CFRunLoopRun()

    terminal.restore()
}

func getKeyboardSubscription<Message>(subscriptions: [Sub<Message>]) -> ((KeyEvent) -> Message)? {
    for subscription in subscriptions {
        switch subscription {
        case let .Keyboard(fn):
            return fn
        default:
            break
        }
    }

    return nil
}

func getTerminalResizeSubscription<Message>(subscriptions: [Sub<Message>]) -> ((Size) -> Message)? {
    for subscription in subscriptions {
        switch subscription {
        case let .TerminalSize(fn):
            return fn
        default:
            break
        }
    }
    
    return nil
}

func getCursorSubscription<Message>(subscriptions: [Sub<Message>]) -> ((Cursor) -> Message)? {
    for subscription in subscriptions {
        switch subscription {
        case let .Cursor(fn):
            return fn
        default:
            break
        }
    }
    
    return nil
}

func async(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(qos: .userInteractive) { block() }
}
