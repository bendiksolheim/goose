import GitLib
import Bow
import BowEffects

func config() -> Task<GitConfig> {
    return Git.config.all().exec()
        .map { Git.config.parse($0.output) }^
}
