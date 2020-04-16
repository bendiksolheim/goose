import Foundation
import Darwin
import Termbox
import os.log
import ReactiveSwift

enum Sub<Message> {
    case cursor((UInt, UInt) -> Message)
    case keyboard((KeyEvent) -> Message)
    case none
}

func cursor<Message>(_ callback: @escaping (UInt, UInt) -> Message) -> Sub<Message> {
    return Sub.cursor(callback)
}

func keyboard<Message>(_ callback: @escaping (KeyEvent) -> Message) -> Sub<Message> {
    return Sub.keyboard(callback)
}

enum Cmd<T> {
    case cmd(T)
    case task(() -> T)
    case exit
    case none
}

func task<Message>(_ task: @escaping () -> Message) -> Cmd<Message> {
    return .task(task)
}

func run<Model: Equatable, Message>(
    initialize: () -> (Model, Cmd<Message>),
    render: @escaping (Model) -> [Line<Message>],
    update: @escaping (Message, Model) -> (Model, Cmd<Message>),
    subscriptions: [Sub<Message>]) {
    do {
        try Termbox.initialize()
    } catch let error {
        print(error)
        return
    }
    
    let keyboardSubscription = getKeyboardSubscription(subscriptions: subscriptions)
    
    let termboxDispatchQueue = DispatchQueue(label: "termbox.queue.producer", qos: .background)

    Termbox.outputMode = .color256
    let app = TermboxScreen()
    let buffer = Buffer(size: app.size)
    
    let (initialModel, initialCommand) = initialize()
    var model = initialModel
    var renderedContent: [Line<Message>]?
    
    let (messageConsumer, messageProducer) = Signal<Message, Never>.pipe()
    let (commandConsumer, commandProducer) = Signal<Cmd<Message>, Never>.pipe()
    
    messageConsumer.observeValues { message in
        //os_log("message: %{public}@", "\(message)")
        let (updatedModel, command) = update(message, model)
        model = updatedModel
        DispatchQueue.main.async {
            commandProducer.send(value: command)
        }
        renderedContent = renderToScreen(buffer, app, model, render)
    }
    
    commandConsumer.observeValues { command in
        switch command {
        case .cmd(let message):
            DispatchQueue.main.async {
                messageProducer.send(value: message)
            }
        case .task(let task):
            let message = task()
            DispatchQueue.main.async {
                messageProducer.send(value: message)
            }
        case .exit:
            messageProducer.sendCompleted()
            commandProducer.sendCompleted()
        case .none:
            break;
        }
    }
    
    commandProducer.send(value: initialCommand)
    
    termboxDispatchQueue.async {
        var polling = true
        while polling {
            if let event = app.pollEvent() {
                switch event {
                case .key(let key):
                    var bubble = false
                    switch key {
                    case .char(let char):
                        switch char {
                        case .j:
                            buffer.moveCursor(.down)
                            renderedContent = renderToScreen(buffer, app, model, render)
                        case .k:
                            buffer.moveCursor(.up)
                            renderedContent = renderToScreen(buffer, app, model, render)
                        default:
                            bubble = true
                            let (_, y) = buffer.cursor
                            if let line = renderedContent?[Int(y)] {
                                for (eventChar, messageFn) in line.events {
                                    if (eventChar == char) {
                                        bubble = false
                                        DispatchQueue.main.async {
                                            messageProducer.send(value: messageFn())
                                        }
                                    }
                                }
                            }
                        }
                    case .ctrl(let char):
                        switch char {
                        case .c:
                            polling = false
                            messageProducer.sendCompleted()
                            commandProducer.sendCompleted()
                        default:
                                break
                        }
                    default:
                        continue
                    }
                    if bubble {
                        if let message = keyboardSubscription?(key) {
                            DispatchQueue.main.async {
                                messageProducer.send(value: message)
                            }
                        }
                    }
                case .window(let width, let height):
                    os_log("New width %{public}d height %{public}d", width, height)
                }
            }
        }
    }
    
    let runLoop = CFRunLoopGetCurrent()
    messageConsumer.observeCompleted {
        CFRunLoopStop(runLoop)
    }
    CFRunLoopRun()
    
    app.teardown()
}

func renderToScreen<Model, Message>(_ buffer: Buffer, _ screen: TermboxScreen, _ model: Model, _ render: (Model) -> [Line<Message>]) -> [Line<Message>] {
    let content = render(model)
    let lines = content.map { $0.chars }
    buffer.clear()
    for y in 0..<lines.count {
        let line = lines[y]
        for x in 0..<line.count {
            let char = line[x]
            buffer.write(char, x: x, y: y)
        }
    }
    
    DispatchQueue.main.async {
        screen.render(buffer: buffer)
    }
    
    return content
}

func getKeyboardSubscription<Message>(subscriptions: [Sub<Message>]) -> ((KeyEvent) -> Message)? {
    for subscription in subscriptions {
        switch subscription {
        case .keyboard(let fn):
            return fn
        default:
            break;
        }
    }
    
    return nil
}
