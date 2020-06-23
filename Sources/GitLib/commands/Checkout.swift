import Foundation

public struct Checkout {
    public static func head(files: [String]) -> GitCommand {
        GitCommand(["checkout", "HEAD", "--"] + files)
    }
}
