import GitLib
import Tea
import Bow

func getResultMessage(_ processResult: LowLevelProcessResult) -> String {
    if processResult.exitCode == 0 {
        return "Git finished"
    } else {
        let output = processResult.output.split(regex: "\n").last ?? ""
        return "\(output) ... [Hit $ to see git output for details]"
    }
}
