import Foundation
import Termbox

enum Event {
    case Key(KeyEvent)
    case Window(width: Int, height: Int)
}
