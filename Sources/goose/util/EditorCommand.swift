import Foundation
import Slowbox
import Tea

func getEditorCommand(event: KeyEvent) -> Cmd<Message> {
    switch event {
    case .j:
        return Editor.moveCursor(0, 1)
    case .k:
        return Editor.moveCursor(0, -1)
//    case .CtrlE:
//        return .MoveScreen(1)
//    case .CtrlY:
//        return .MoveScreen(-1)
    case .CtrlD:
        return Editor.scroll(.Percentage(50))
    case .CtrlU:
        return Editor.scroll(.Percentage(-50))
    default:
        return Cmd.none()
    }
}
