//
//  FoldableSection.swift
//  magit
//
//  Created by Bendik Solheim on 11/04/2020.
//

import Foundation

func Section(title: Line, items: [Line], open: Bool) -> [Line] {
    return [title] + ( open ? items + [EmptyLine()] : [EmptyLine()])
}
