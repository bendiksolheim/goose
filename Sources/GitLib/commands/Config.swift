import Foundation

public struct Config: Equatable, Encodable {
    let path: String
    
    public func all() -> GitCommand {
        GitCommand(path, ["config", "--list"])
    }
    
    public func parse(_ input: String) -> GitConfig {
        let lines = input.split(regex: "\n")
        var configs: [String: String] = [:]
        for line in lines {
            let matches = line.match(regex: "(?<key>.*)=(?<value>.*)")
            if let key = matches["key"], let value = matches["value"] {
                configs[key] = value
            }
        }
        return GitConfig(configs)
    }
}
