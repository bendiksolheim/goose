//
//  FoldableSection.swift
//  magit
//
//  Created by Bendik Solheim on 11/04/2020.
//

import Foundation
import Ashen

func Section(title: LabelView, items: [LabelView], open: Bool) -> FlowLayout {
    let components = [title] + ( open ? items : [])
    let height = Dimension.literal(components.count + 1)
    let width = Dimension.max
    
    return FlowLayout.vertical(size: DesiredSize(width: width, height: height), components: components)
}
