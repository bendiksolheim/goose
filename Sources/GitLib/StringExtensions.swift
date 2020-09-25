import Foundation

public extension String {
    subscript(value: Int) -> Character {
        if self.count == 0 {
            return " "
        } else {
            return self[index(at: value)]
        }
    }

    func split(regex pattern: String) -> [String] {
        // ### Crashes when you pass invalid `pattern`
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: self, range: NSRange(0 ..< utf16.count))
        let ranges = [startIndex ..< startIndex] + matches.map { Range($0.range, in: self)! } + [endIndex ..< endIndex]
        return (0 ... matches.count).map { String(self[ranges[$0].upperBound ..< ranges[$0 + 1].lowerBound]) }
    }
}

private extension String {
    func index(at offset: Int) -> String.Index {
        index(startIndex, offsetBy: offset)
    }
}
