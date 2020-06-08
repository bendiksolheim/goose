import Foundation

public struct Checkout {
    public static func head(files: [String]) -> GitCommand {
        GitCommand(arguments: ["checkout", "HEAD", "--"] + files)
    }
}
