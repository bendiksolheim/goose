import Foundation
import GitLib
import BowEffects

extension GitCommand {
    func exec(_ input: String? = nil) -> Task<LowLevelProcessResult> {
        execute(process: ProcessDescription.git(self), input: input)
    }
}
