import Foundation
import tea

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

if let basePath = locateGitDir() {
    run(initialize: initialize(basePath: basePath), render: render, update: update, subscriptions: subscriptions)
} else {
    print("\(FileManager.default.currentDirectoryPath) is not inside a git directory")
}
