import Foundation
import Darwin
import Termbox
import os.log
import ReactiveSwift

public enum Sub<Message> {
    case cursor((ScrollMessage) -> Message)
    case keyboard((KeyEvent) -> Message)
    case none
}

public func cursor<Message>(_ callback: @escaping (ScrollMessage) -> Message) -> Sub<Message> {
    return Sub.cursor(callback)
}

public func keyboard<Message>(_ callback: @escaping (KeyEvent) -> Message) -> Sub<Message> {
    return Sub.keyboard(callback)
}

public func run<Model: Equatable, Message>(
    initialize: () -> (Model, Cmd<Message>),
    render: @escaping (Model) -> Window<Message>,
    update: @escaping (Message, Model) -> (Model, Cmd<Message>),
    subscriptions: [Sub<Message>]) {
    
    
    let termboxDispatchQueue = DispatchQueue(label: "termbox.queue.producer", qos: .background)
    let taskDispatchQueue = DispatchQueue(label: "tea.task.queue", qos: .userInitiated)

    var app = TermboxScreen()
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
                    os_log("Event: %{public}@", "\(event)")
                    switch event {
                    case .key(let key):
                        switch key {
                        case .char(let char):
                            switch char {
                            case .j:
                                if let sub = cursorSubscription {
                                    let msg = sub(.move(1))
                                    async { messageProducer.send(value: msg) }
                                }
                            
                            case .k:
                            if let sub = cursorSubscription {
                                let msg = sub(.move(-1))
                                messageProducer.send(value: msg)
                            }
                            
                            default:
                                buffer.cursors.forEach { cursor in
                                    if let events = buffer.cell(cursor: cursor)?.events {
                                        events.forEach { (evChar, message) in
                                            if evChar == key {
                                                async { messageProducer.send(value: message) }
                                            }
                                        }
                                    }
                                }
                            }
                        
                        case .fn(_):
                            buffer.cursors.forEach { cursor in
                                if let events = buffer.cell(cursor: cursor)?.events {
                                    events.forEach { (evChar, message) in
                                        if evChar == key {
                                            async { messageProducer.send(value: message) }
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
                            
                            case .d:
                            if let sub = cursorSubscription {
                                let msg = sub(.move(10))
                                async { messageProducer.send(value: msg) }
                            }
                            
                            case .u:
                            if let sub = cursorSubscription {
                                let msg = sub(.move(-10))
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
                    
                    case .window(let width, let height):
                        os_log("New width %{public}d height %{public}d",    width, height)
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
            
        case .Command(let message):
            async { messageProducer.send(value: message) }
                
        case .Commands(let commands):
            for command in commands {
                async { commandProducer.send(value: command) }
            }
            
        case .Task(let task):
            taskDispatchQueue.async {
                messageProducer.send(value: task())
            }
            
        case .Process(let process):
            polling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                app.teardown()
                os_log("starting process")
                let message = process()
                os_log("process ended")
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
            
        /*case .cmd(let message):
            async { messageProducer.send(value: message) }
            
        case .task(let task):
            let message = task()
            async { messageProducer.send(value: message) }
            
        case .asyncTask(let task):
            taskDispatchQueue.async {
                task({ message in
                    async { messageProducer.send(value: message) }
                })
            }
            
        case .delayedTask(let interval, let task):
            let message = task()
            taskDispatchQueue.asyncAfter(deadline: .now() + interval)
                { messageProducer.send(value: message) }

        case .process(let process):
            polling = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                app.teardown()
                os_log("starting process")
                let message = process()
                os_log("process ended")
                polling = true
                
                async {
                    try! app.setup()
                    let window = render(model)
                    renderToScreen(buffer, app, window)
                    startEventPolling()
                }
                    
                async { messageProducer.send(value: message) }
                
            }
            
        case .exit:
            messageProducer.sendCompleted()
            commandProducer.sendCompleted()
            
        case .none:
            break;*/
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
        case .keyboard(let fn):
            return fn
        default:
            break;
        }
    }
    
    return nil
}

func getCursorSubscription<Message>(subscriptions: [Sub<Message>]) -> ((ScrollMessage) -> Message)? {
    for subscription in subscriptions {
        switch subscription {
        case .cursor(let fn):
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
