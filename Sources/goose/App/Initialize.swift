import Foundation
import Tea
import GitLib

func initialize(basePath: String) -> () -> (Model, Cmd<Message>) {
    {
        let git = Git(path: basePath)
        return (Model(git: git,
                views: [View(buffer: .StatusBuffer(StatusModel(info: .Loading, visibility: Visibility())))],
//                views: [View(buffer: .LogBuffer(.Loading))],
                info: .None,
                menu: Menu.empty(),
                gitLog: GitLogModel()),
//                    terminal: TerminalModel(cursor: terminalInfo.cursor, size: terminalInfo.size)),
//                getLog(git: git))
                getStatus(git: git))
    }
}
