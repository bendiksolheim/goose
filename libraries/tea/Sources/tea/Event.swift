import Foundation
import Termbox

enum Event {
    case key(KeyEvent)
    case window(width: Int, height: Int)
}