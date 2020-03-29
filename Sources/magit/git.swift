import Foundation

private let git = "/usr/local/bin/git"

func branchName() -> String {
    let process = ProcessDescription(
        workingDirectory: currentDirectory(),
        executable: git,
        arguments: ["symbolic-ref", "--short", "HEAD"])
    
    let result = run(process: process)
    return result.output
}

private func currentDirectory() -> String {
    return FileManager.default.currentDirectoryPath
}

