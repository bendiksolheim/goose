import Foundation

public struct Restore {
    public static func file(_ file: String, staged: Bool = false) -> GitCommand {
        GitCommand(
            arguments: ["restore", file] + (staged ? ["--staged"] : [])
        )
    }
}
