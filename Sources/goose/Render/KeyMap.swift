import Foundation
import Tea

func renderKeyMap(_ keyMap: KeyMap) -> Container {
    return Container(FlexStyle(direction: .Column), keyMap.map
        .filter { $0.value.visible }
        .map { key in
            Content<Message>(Text(key.key.stringValue(), .Magenta) + " \(key.value.command)")
        })
}
