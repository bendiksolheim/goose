//
//  git.swift
//  Ashen
//
//  Created by Bendik Solheim on 28/03/2020.
//

import Foundation
import os.log
import BowEffects
import GitLib


public struct ProcessDescription {
    let workingDirectory: String
    let executable: String
    let arguments: [String]
    
    private init(workingDirectory: String, executable: String, arguments: [String]) {
        self.workingDirectory = workingDirectory
        self.executable = executable
        self.arguments = arguments
    }
    
    public static func git(_ cmd: GitCommand) -> ProcessDescription {
        ProcessDescription(
            workingDirectory: currentDirectory(),
            executable: gitExecutable,
            arguments: cmd.arguments
        )
    }
}

public struct ProcessResult {
    let output: String
    let exitCode: Int32
}

func execute(process: ProcessDescription) -> Task<ProcessResult> {
    return Task.invoke {
        logCommand(process: process)
        let task = Process()
        task.launchPath = process.executable
        task.arguments = process.arguments
        task.currentDirectoryPath = process.workingDirectory
    
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe
        task.launch()
    
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        let exitCode = task.terminationStatus
        if exitCode == 0 {
            let stdOutput = String(data: stdoutData, encoding: String.Encoding.utf8)
            return ProcessResult(output: stdOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", exitCode: task.terminationStatus)
        } else {
            let errOutput = String(data: stderrData, encoding: String.Encoding.utf8)
            throw StringError(errOutput ?? "Command exited without error message")
        }
    }
}

private func logCommand(process: ProcessDescription) -> Void {
    let executedCommand = ([process.executable] + process.arguments).joined(separator: " ")
    let command = "Process(executable=\(process.executable), arguments=\(process.arguments), workingDirectory=\(process.workingDirectory), cmd=\(executedCommand)"
    os_log("%{public}@", command)
}

private let gitExecutable = "/usr/local/bin/git"

private func currentDirectory() -> String {
    return FileManager.default.currentDirectoryPath
}
