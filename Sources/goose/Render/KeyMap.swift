import Foundation
import Tea

func renderMenu(_ keyMap: KeyMap) -> Node {
    let content: [Node] = keyMap.sections.map { section in
        let keys = section.map.filter {
                    $0.value.visible
                }
                .map { key in
                    Text(FormattedText(" " + key.key.stringValue(), .Magenta) + " \(key.value.command)")

                }
        return Vertical(padding: Padding(right: 5)) {
            [Text(FormattedText(section.title, .Blue))]
            keys
        }
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
        [Horizontal { content }]
        [EmptyLine()]
        [Text(FormattedText("Essential commands", .Blue))]
        [essential]
    }
}
