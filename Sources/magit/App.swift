//
//  App.swift
//  magit
//
//  Created by Bendik Solheim on 12/04/2020.
//

import Foundation
import Darwin
import Termbox
import os.log
import ReactiveSwift

enum Cmd<T> {
    case task(() -> T)
    case none
}

func task<Message>(_ task: @escaping () -> Message) -> Cmd<Message> {
    return .task(task)
}

func run<Model: Equatable, Message>(
    initialize: () -> (Model, Cmd<Message>),
    render: @escaping (Model) -> [AttrCharType],
    update: @escaping (Message, Model) -> (Model, Cmd<Message>)) {
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
        let content = render(model)
        buffer.write(lines: content)
        
        DispatchQueue.main.async {
            app.render(buffer: buffer)
        }
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
