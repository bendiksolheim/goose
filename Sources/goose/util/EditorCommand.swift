import Foundation
import Slowbox
import Tea

func getGeneralCommand(event: KeyEvent) -> Cmd<Message> {
    switch event {
    case .q:
        return Cmd.message(.DropBuffer)
    case .question:
        return Cmd.message(.Action(.ToggleKeyMap(true)))
    case .esc:
        return Cmd.message(.Action(.ToggleKeyMap(false)))
    case .j:
        return Cursor.move(0, 1)
    case .k:
        return Cursor.move(0, -1)
//    case .CtrlE:
//        return .MoveScreen(1)
//    case .CtrlY:
//        return .MoveScreen(-1)
    case .CtrlD:
        return Cursor.scroll(.Percentage(50))
    case .CtrlU:
        return Cursor.scroll(.Percentage(-50))
    default:
        return Cmd.none()
    }
}
