//
//  Event.swift
//  magit
//
//  Created by Bendik Solheim on 11/04/2020.
//

import Foundation
import Termbox

enum Event {
    case key(KeyEvent)
    case window(width: Int, height: Int)
    //case tick(Float)
    //case log(String)
}
