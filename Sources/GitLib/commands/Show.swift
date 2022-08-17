import Foundation

public struct Show: Equatable, Encodable {
    let path: String
    
    public func patch(_ ref: [String]) -> GitCommand {
        GitCommand(path, ["show", "-s", "-z", "--format=\(commitFormat)", "-p"] + ref)
    }
    
    public func plain(_ ref: [String]) -> GitCommand {
        GitCommand(path, ["show", "-s", "-z", "--format=\(commitFormat)"] + ref)
    }
    
    public func stat(_ ref: String) -> GitCommand {
        GitCommand(path, ["show", "--format=", "--numstat"] + [ref])
    }
}
