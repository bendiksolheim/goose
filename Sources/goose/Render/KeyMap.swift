import Foundation
import Tea

func renderKeyMap(_ keyMap: KeyMap) -> Node {
    let content: [Node] = keyMap.map
            .filter {
                $0.value.visible
            }
            .map { key in
                Text(FormattedText(key.key.stringValue(), .Magenta) + " \(key.value.command)")
            }

    let essential = Horizontal {
        Vertical {
            Text(FormattedText("q ", .Magenta))
            Text(FormattedText("<enter> ", .Magenta))
        }
        Vertical {
            Text("bury current buffer")
            Text("visit thing at point")
        }
    }

    return Vertical(.Fill, .Percentage(50)) {
        [Text(FormattedText("Transient commands", .Blue))]
        content
        [EmptyLine()]
        [Text(FormattedText("Essential commands", .Blue))]
        [essential]
    }
}
