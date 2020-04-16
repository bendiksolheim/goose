//
//  Line.swift
//  magit
//
//  Created by Bendik Solheim on 15/04/2020.
//

import Foundation

typealias LineEventHandler<Message> = (CharKeyEvent, () -> Message)

struct Line<Message> {
    let chars: [AttrCharType]
    let events: [LineEventHandler<Message>]
    
    init(_ text: TextType, _ events: [LineEventHandler<Message>] = []) {
        let chars = text.chars
        self.chars = chars
        self.events = events
    }
}

func EmptyLine<Message>() -> Line<Message> {
    Line(" ")
}
