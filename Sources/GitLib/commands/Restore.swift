import Foundation

public struct Restore {
    public static func file(_ files: [String], staged: Bool = false) -> GitCommand {
        GitCommand(
            arguments: ["restore"] + files + (staged ? ["--staged"] : [])
        )
    }
}
