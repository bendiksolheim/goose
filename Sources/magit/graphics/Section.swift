//
//  FoldableSection.swift
//  magit
//
//  Created by Bendik Solheim on 11/04/2020.
//

import Foundation

func Section<Message>(title: Line<Message>, items: [Line<Message>], open: Bool) -> [Line<Message>] {
    return [title] + ( open ? items + [EmptyLine()] : [EmptyLine()])
}
