import Foundation

public struct GitLog: Equatable, Encodable {
    let path: String

    public func log(config: GitLogConfig) -> GitCommand {
        GitCommand(path, ["log"] + (config.graph ? ["--graph"] : []) + ["--format=\(commitFormat)", "-n", "\(config.num)"])
    }

}

public struct GitLogConfig {
    let graph: Bool
    let num: Int

    public init(graph: Bool = false, num: Int = 10) {
        self.graph = graph
        self.num = num
    }
}