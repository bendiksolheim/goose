//
//  git.swift
//  Ashen
//
//  Created by Bendik Solheim on 28/03/2020.
//

import Foundation
import os.log

func run(cmd: String, args: String...) -> String? {
    return run(cmd: cmd, args: args)
}

func run(cmd: String, args: [String]) -> String? {
    logCommand(cmd: cmd, args: args)
    let task = Process()
    task.launchPath = cmd
    task.arguments = args
    task.currentDirectoryPath = currentDirectory()
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return output
}

private func currentDirectory() -> String {
    return FileManager.default.currentDirectoryPath
}

private func logCommand(cmd: String, args: [String]) -> Void {
    let command = "\(cmd) \(args.joined(separator: " "))"
    os_log("Comand: %{public}@", command)
}
