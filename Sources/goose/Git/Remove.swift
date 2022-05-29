import Foundation
import BowEffects

func remove(files: [String]) -> IO<Error, Message> {
    IO.invoke {
        let allExists = files.map {
                    FileManager.default.fileExists(atPath: $0)
                }
                .allSatisfy {
                    $0
                }

        if allExists {
            do {
                try files.forEach { file in
                    try FileManager.default.removeItem(atPath: file)
                }
                return .CommandSuccess
            } catch {
                return .Info(.Message("File not found"))
            }
        } else {
            return .Info(.Message("File not found"))
        }
    }
}
