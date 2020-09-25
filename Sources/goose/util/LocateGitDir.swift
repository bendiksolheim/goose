import Foundation

func locateGitDir() -> String? {
    let currentDirectory = FileManager.default.currentDirectoryPath
    let url = URL(fileURLWithPath: currentDirectory)
    return url
        .pathComponents
        .reduce([]) { acc, cur in
            acc + [acc.last?.appendingPathComponent(cur) ?? URL(fileURLWithPath: cur)]
        }
        .reversed()
        .first(where: { FileManager.default.isGitDirectory(atPath: $0) })?.path
}
