import Foundation

public struct Restore {
    public static func file(_ files: [String], staged: Bool = false) -> GitCommand {
        GitCommand(["restore"] + files + (staged ? ["--staged"] : []))
    }
}
