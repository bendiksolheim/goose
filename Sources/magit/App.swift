import Foundation
import Darwin
import Termbox
import os.log
import ReactiveSwift

enum Sub<Message> {
    case cursor((UInt, UInt) -> Message)
    case none
}

func cursor<Message>(_ callback: @escaping (UInt, UInt) -> Message) -> Sub<Message> {
    return Sub.cursor(callback)
}

enum Cmd<T> {
    case task(() -> T)
    case none
}

func task<Message>(_ task: @escaping () -> Message) -> Cmd<Message> {
    return .task(task)
}

func renderToScreen<Model>(_ buffer: Buffer, _ screen: TermboxScreen, _ model: Model, _ render: (Model) -> [Line]) {
    let content = render(model)
    let lines = content.map { $0.chars }
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
}

func run<Model: Equatable, Message>(
    initialize: () -> (Model, Cmd<Message>),
    render: @escaping (Model) -> [Line],
    update: @escaping (Message, Model) -> (Model, Cmd<Message>),
    subscriptions: [Sub<Message>]) {
    do {
        try Termbox.initialize()
    } catch let error {
        print(error)
        return
    }
    
    let termboxDispatchQueue = DispatchQueue(label: "termbox.queue.producer", qos: .background)

    Termbox.outputMode = .color256
    let app = TermboxScreen()
    let buffer = Buffer(size: app.size)
    
    let (initialModel, initialCommand) = initialize()
    var model = initialModel
    
    let (messageConsumer, messageProducer) = Signal<Message, Never>.pipe()
    let (commandConsumer, commandProducer) = Signal<Cmd<Message>, Never>.pipe()
    
    messageConsumer.observeValues { message in
        let (updatedModel, command) = update(message, model)
        DispatchQueue.main.async {
            commandProducer.send(value: command)
        }
        model = updatedModel
        renderToScreen(buffer, app, model, render)
        /*let content = render(model)
        buffer.write(lines: content)
        
        DispatchQueue.main.async {
            app.render(buffer: buffer)
        }*/
    }
    
    commandConsumer.observeValues { command in
        switch command {
        case .task(let task):
            let message = task()
            DispatchQueue.main.async {
                messageProducer.send(value: message)
            }
        case .none:
            break;
        }
    }
    
    commandProducer.send(value: initialCommand)
    
    termboxDispatchQueue.async {
        var polling = true
        while polling {
            os_log("termbox poll event")
            if let event = app.pollEvent() {
                switch event {
                case .key(let key):
                    switch key {
                    case .char(let char):
                        switch char {
                        case .q:
                            os_log("quitting")
                            polling = false
                            messageProducer.sendCompleted()
                            commandProducer.sendCompleted()
                        case .j:
                            buffer.moveCursor(.down)
                            renderToScreen(buffer, app, model, render)
                        case .k:
                            buffer.moveCursor(.up)
                            renderToScreen(buffer, app, model, render)
                        default:
                            let letter = char.toString
                            os_log("Letter: %{public}@", letter)
                            let attrChar = AttrChar(letter)
                            buffer.write(attrChar, x: 0, y: 0)
                        }
                    default:
                        continue
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
