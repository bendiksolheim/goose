import Foundation

enum Command<Msg> {
    case None
    case Command(Msg)
    case Commands([Cmd<Msg>])
    case Task(() -> Msg)
    case AsyncTask(TimeInterval, () -> Msg)
    case Process(() -> Msg)
    case Quit
}

public struct Cmd<Msg> {
    let cmd: Command<Msg>

    init(_ cmd: Msg) {
        self.cmd = .Command(cmd)
    }

    init(_ cmd: @escaping () -> Msg) {
        self.cmd = .Task(cmd)
    }

    init(_ type: Command<Msg>) {
        cmd = type
    }

    public static func message(_ msg: Msg) -> Cmd<Msg> {
        Cmd(msg)
    }

    public static func none() -> Cmd<Msg> {
        Cmd(.None)
    }

    public static func batch(_ cmds: Cmd<Msg>...) -> Cmd<Msg> {
        Cmd(.Commands(cmds.map { $0 }))
    }
}
