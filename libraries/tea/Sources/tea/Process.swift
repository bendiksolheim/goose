import Foundation

public class TProcess {
    public static func quit<Msg>() -> Cmd<Msg> {
        Cmd(.Quit)
    }

    public static func sleep(_ interval: TimeInterval) -> Task<Void> {
        let cappedInterval = max(interval, 0.0)
        let microseconds = UInt32(cappedInterval * 1_000_000)
        return Task<Void> { usleep(microseconds) }
    }

    public static func spawn<R>(_ process: @escaping () -> R) -> Task<R> {
        Task(process, .External)
    }
}
