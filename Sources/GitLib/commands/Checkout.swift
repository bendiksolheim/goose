import Foundation

public struct Checkout {
    public static func head(file: String) -> GitCommand {
        GitCommand(arguments: ["checkout", "HEAD", "--", file])
    }
}
