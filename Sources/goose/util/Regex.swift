import Foundation

extension NSString {
    public func match(regex regexString: String) -> [String: String] {
        let string = self as String
        guard let nameRegex = try? NSRegularExpression(pattern: "\\(\\?\\<(\\w+)\\>", options: []) else { return [:] }
        let nameMatches = nameRegex.matches(in: regexString, options: [], range: NSMakeRange(0, regexString.count))
        let names = nameMatches.map { (textCheckingResult) -> String in
            (regexString as NSString).substring(with: textCheckingResult.range(at: 1))
        }
        guard let regex = try? NSRegularExpression(pattern: regexString, options: []) else { return [:] }
        let result = regex.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count))
        var dict = [String: String]()
        for name in names {
            if let range = result?.range(withName: name),
                range.location != NSNotFound {
                dict[name] = substring(with: range)
            }
        }
        return dict.count > 0 ? dict : [:]
    }
}
