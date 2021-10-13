import Foundation
import TermSwift

enum Unit {
    case Absolute(Int)
    case Percentage(Int)
}

enum EditorCommand {
    case MoveCursor(Int)
    case MoveScreen(Int)
    case Scroll(Unit)
    case None
}

func getEditorCommand(event: KeyEvent) -> EditorCommand {
    switch event {
    case .j:
        return .MoveCursor(1)
    case .k:
        return .MoveCursor(-1)
    case .CtrlE:
        return .MoveScreen(1)
    case .CtrlY:
        return .MoveScreen(-1)
    case .CtrlD:
        return .Scroll(.Percentage(50))
    case .CtrlU:
        return .Scroll(.Percentage(-50))
    default:
        return .None
    }
}
