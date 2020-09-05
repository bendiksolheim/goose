import Foundation

extension FileManager {
    func isGitDirectory(atPath: URL) -> Bool {
        isDirectory(atPath: atPath.appendingPathComponent(".git").path)
    }
    
    func isDirectory(atPath: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: atPath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
