//
//  Line.swift
//  magit
//
//  Created by Bendik Solheim on 15/04/2020.
//

import Foundation

struct Line {
    let chars: [AttrCharType]
    
    init(_ text: TextType) {
        let chars = text.chars
        self.chars = chars
    }
}

func EmptyLine() -> Line {
    Line(" ")
}
