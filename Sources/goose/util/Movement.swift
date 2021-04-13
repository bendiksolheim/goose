import Foundation
import TermSwift

func getYMovement(event: KeyEvent) -> Int? {
    switch event {
    case .j:
        return 1
    case .k:
        return -1
    case .CtrlD:
        return 10
    case .CtrlU:
        return -10
    default:
        return nil
    }
}
