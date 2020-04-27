import Foundation
import Darwin
import Termbox
import os.log
import ReactiveSwift

public enum Sub<Message> {
    case cursor((UInt, UInt) -> Message)
    case keyboard((KeyEvent) -> Message)
    case none
}

public func cursor<Message>(_ callback: @escaping (UInt, UInt) -> Message) -> Sub<Message> {
    return Sub.cursor(callback)
}

public func keyboard<Message>(_ callback: @escaping (KeyEvent) -> Message) -> Sub<Message> {
    return Sub.keyboard(callback)
}

public enum Cmd<T> {
    case cmd(T)
    case task(() -> T)
    case asyncTask((@escaping (T) -> Void) -> Void)
    case process(() -> T)
    case exit
    case none
}

public func task<Message>(_ task: @escaping () -> Message) -> Cmd<Message> {
    return .task(task)
}

public func asyncTask<Message>(_ task: @escaping (@escaping (Message) -> Void) -> Void) -> Cmd<Message> {
    return .asyncTask(task)
}

public func process<Message>(_ process: @escaping () -> Message) -> Cmd<Message> {
    return .process(process)
}

public func run<Model: Equatable, Message>(
    initialize: () -> (Model, Cmd<Message>),
    render: @escaping (Model) -> [Line<Message>],
    update: @escaping (Message, Model) -> (Model, Cmd<Message>),
    subscriptions: [Sub<Message>]) {
    
    let keyboardSubscription = getKeyboardSubscription(subscriptions: subscriptions)
    
    let termboxDispatchQueue = DispatchQueue(label: "termbox.queue.producer", qos: .background)
    let taskDispatchQueue = DispatchQueue(label: "tea.task.queue", qos: .userInitiated)

    var app = TermboxScreen()
    try! app.setup()
    var buffer = Buffer(size: app.size)
    var polling = true
    
    let (initialModel, initialCommand) = initialize()
    var model = initialModel
    var renderedContent: [Line<Message>]?
    
    let (messageConsumer, messageProducer) = Signal<Message, Never>.pipe()
    let (commandConsumer, commandProducer) = Signal<Cmd<Message>, Never>.pipe()
    
    func startEventPolling() {
    termboxDispatchQueue.async {
        while polling {
            if let event = app.nextEvent() {
                os_log("Event: %{public}@", "\(event)")
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
                                    if (eventChar == .char(char)) {
                                        bubble = false
                                        DispatchQueue.main.async {
                                            messageProducer.send(value: messageFn())
                                        }
                                    }
                                }
                            }
                        }
                    case .fn(let key):
                        bubble = true
                        let (_, y) = buffer.cursor
                        if let line = renderedContent?[Int(y)] {
                            for (eventChar, messageFn) in line.events {
                                if (eventChar == .fn(key)) {
                                    bubble = false
                                    DispatchQueue.main.async {
                                        messageProducer.send(value: messageFn())
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
                        break
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
    }
    
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
        case .asyncTask(let task):
            taskDispatchQueue.async {
                task({ message in
                    DispatchQueue.main.async {
                        messageProducer.send(value: message)
                    }
                })
            }
        case .process(let process):
            polling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                app.teardown()
                os_log("starting process")
                let message = process()
                os_log("process ended")
                polling = true
                DispatchQueue.main.async {
                    try! app.setup()
                    renderedContent = renderToScreen(buffer, app, model, render)
                    startEventPolling()
                }
                    
                DispatchQueue.main.async {
                    messageProducer.send(value: message)
                }
                
            }
        case .exit:
            messageProducer.sendCompleted()
            commandProducer.sendCompleted()
        case .none:
            break;
        }
    }
    
    commandProducer.send(value: initialCommand)
    startEventPolling()
    
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
