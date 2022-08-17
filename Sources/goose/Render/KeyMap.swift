import Foundation
import Tea

func renderKeyMap(_ keyMap: KeyMap) -> Node {
    let content: [Node] = [Text("___________________________")].combine(keyMap.map
            .filter {
                $0.value.visible
            }
            .map { key in
                Text(FormattedText(key.key.stringValue(), .Magenta) + " \(key.value.command)")
            })
    return Vertical(.Fill, .Percentage(50)) {
        content
    }
}
