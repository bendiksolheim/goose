import Foundation

public typealias XDelta = Int
public typealias YDelta = Int

public class Tea {
    public static func quit<Msg>() -> Cmd<Msg> {
        Cmd(.Quit)
    }
    
    public static func moveCursor<Msg>(_ dx: XDelta, _ dy: YDelta) -> Cmd<Msg> {
        Cmd(.Terminal(.MoveCursor(dx, dy)))
    }

    public static func sleep(_ interval: TimeInterval) -> Task<Void> {
        let cappedInterval = max(interval, 0.0)
        return Task<Void>({}, .Async(cappedInterval))
    }

    public static func spawn<R>(_ process: @escaping () -> R) -> Task<R> {
        Task(process, .External)
    }
}
