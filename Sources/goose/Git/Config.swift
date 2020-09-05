import GitLib
import Bow
import BowEffects

func config(git: Git) -> Task<GitConfig> {
    return git.config.all().exec()
        .map { git.config.parse($0.output) }^
}
