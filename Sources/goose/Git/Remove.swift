import Foundation

func remove(files: [String]) -> Message {
    let fileManager = FileManager.default

    let allExists = files.map { fileManager.fileExists(atPath: $0) }.allSatisfy { $0 }

    if allExists {
        do {
            try files.forEach { file in try fileManager.removeItem(atPath: file) }
            return .CommandSuccess
        } catch {
            return .Info(.Message("File not found"))
        }
    } else {
        return .Info(.Message("File not found"))
    }
}
