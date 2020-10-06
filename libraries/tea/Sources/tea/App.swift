import Darwin
import Foundation
import os.log
import ReactiveSwift
import Termbox

public enum Sub<Message> {
    case Cursor((ScrollMessage) -> Message)
    case Keyboard((KeyEvent) -> Message)
    case None
}

public func cursor<Message>(_ callback: @escaping (ScrollMessage) -> Message) -> Sub<Message> {
    Sub.Cursor(callback)
}

public func keyboard<Message>(_ callback: @escaping (KeyEvent) -> Message) -> Sub<Message> {
    Sub.Keyboard(callback)
}

public func run<Model: Equatable, Message>(
    initialize: () -> (Model, Cmd<Message>),
    render: @escaping (Model) -> Window<Message>,
    update: @escaping (Message, Model) -> (Model, Cmd<Message>),
    subscriptions: [Sub<Message>]
) {
    let termboxDispatchQueue = DispatchQueue(label: "termbox.queue.producer", qos: .background)
    let taskDispatchQueue = DispatchQueue(label: "tea.task.queue", qos: .userInitiated)

    let app = TermboxScreen()
    try! app.setup()
    let buffer = Buffer<Message>(size: app.size)
    var polling = true

    let (initialModel, initialCommand) = initialize()
    var model = initialModel
    let window = render(model)
    renderToScreen(buffer, app, window)

    let keyboardSubscription = getKeyboardSubscription(subscriptions: subscriptions)
    let cursorSubscription = getCursorSubscription(subscriptions: subscriptions)

    let (messageConsumer, messageProducer) = Signal<Message, Never>.pipe()
    let (commandConsumer, commandProducer) = Signal<Cmd<Message>, Never>.pipe()

    func startEventPolling() {
        termboxDispatchQueue.async {
            while polling {
                if let event = app.nextEvent() {
                    switch event {
                    case let .Key(key):
                        switch key {
                        case let .char(char):
                            switch char {
                            case .j:
                                if let sub = cursorSubscription {
                                    let msg = sub(.Move(1))
                                    async { messageProducer.send(value: msg) }
                                }

                            case .k:
                                if let sub = cursorSubscription {
                                    let msg = sub(.Move(-1))
                                    messageProducer.send(value: msg)
                                }

                            default:
                                buffer.cursors.forEach { cursor in
                                    if let events = buffer.cell(cursor: cursor)?.events {
                                        events.forEach { evChar, message in
                                            if evChar == key {
                                                async { messageProducer.send(value: message) }
                                            }
                                        }
                                    }
                                }
                            }

                        case .fn:
                            buffer.cursors.forEach { cursor in
                                if let events = buffer.cell(cursor: cursor)?.events {
                                    events.forEach { evChar, message in
                                        if evChar == key {
                                            async { messageProducer.send(value: message) }
                                        }
                                    }
                                }
                            }

                        case let .ctrl(char):
                            switch char {
                            case .c:
                                polling = false
                                messageProducer.sendCompleted()
                                commandProducer.sendCompleted()

                            case .d:
                                if let sub = cursorSubscription {
                                    let msg = sub(.Move(10))
                                    async { messageProducer.send(value: msg) }
                                }

                            case .u:
                                if let sub = cursorSubscription {
                                    let msg = sub(.Move(-10))
                                    async { messageProducer.send(value: msg) }
                                }

                            default:
                                break
                            }

                        default:
                            break
                        }

                        if let message = keyboardSubscription?(key) {
                            async { messageProducer.send(value: message) }
                        }

                    case let .Window(width, height):
                        let newSize = Size(width: width, height: height)
                        buffer.resize(to: newSize)
                        let window = render(model)
                        renderToScreen(buffer, app, window)
                    }
                }
            }
        }
    }

    messageConsumer.observeValues { message in
        let (updatedModel, command) = update(message, model)
        model = updatedModel
        async { commandProducer.send(value: command) }
        let window = render(model)
        renderToScreen(buffer, app, window)
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
            taskDispatchQueue.async {
                messageProducer.send(value: task())
            }
            
        case let .AsyncTask(delay, task):
            taskDispatchQueue.asyncAfter(deadline: .now() + delay) {
                messageProducer.send(value: task())
            }

        case let .Process(process):
            polling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                app.teardown()
                let message = process()
                polling = true

                async {
                    try! app.setup()
                    let window = render(model)
                    renderToScreen(buffer, app, window)
                    startEventPolling()
                }

                async { messageProducer.send(value: message) }
            }

        case .Quit:
            messageProducer.sendCompleted()
            commandProducer.sendCompleted()
        }
    }

    async { commandProducer.send(value: initialCommand) }
    startEventPolling()

    let runLoop = CFRunLoopGetCurrent()
    messageConsumer.observeCompleted {
        CFRunLoopStop(runLoop)
    }
    CFRunLoopRun()

    app.teardown()
}

func renderToScreen<Message>(_ buffer: Buffer<Message>, _ screen: TermboxScreen, _ window: Window<Message>) {
    buffer.clear()
    window.measureIn(buffer)
    window.renderTo(buffer)
    let chars = map(buffer.chars) { $0?.content ?? Char(" ") }

    DispatchQueue.main.async {
        screen.render(buffer: chars)
    }
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

func getCursorSubscription<Message>(subscriptions: [Sub<Message>]) -> ((ScrollMessage) -> Message)? {
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
    DispatchQueue.main.async { block() }
}
