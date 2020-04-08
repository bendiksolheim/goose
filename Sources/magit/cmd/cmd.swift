//
//  git.swift
//  Ashen
//
//  Created by Bendik Solheim on 28/03/2020.
//

import Foundation
import os.log
import BowEffects

public struct ProcessDescription {
    let workingDirectory: String
    let executable: String
    let arguments: [String]
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
    
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
    
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        task.waitUntilExit()
        
        return ProcessResult(output: output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", exitCode: task.terminationStatus)
    }
}

private func logCommand(process: ProcessDescription) -> Void {
    let command = "Process(executable=\(process.executable), arguments=\(process.arguments), workingDirectory=\(process.workingDirectory))"
    os_log("%{public}@", command)
}
