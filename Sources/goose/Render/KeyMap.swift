import Foundation
import tea

func renderKeyMap(_ keyMap: KeyMap) -> Array<Line<Message>> {
    return keyMap.map
        .filter { $0.value.visible }
        .map { key in
            Line(Text(key.key.stringValue(), .Magenta) + " \(key.value.command)")
        }
}
