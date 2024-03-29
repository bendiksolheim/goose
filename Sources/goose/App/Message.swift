import Foundation
import Bow
import Tea
import Slowbox

indirect enum Message {
    case TerminalEvent(TerminalEvent)
    case Action(Action)
    case PushKeyMap(KeyMap)
    case PopKeyMap
    case GitCommand(GitCmd)
    case GitResult([GitLogEntry], GitResult)
    case UpdateStatus(String, StatusModel)
    case UpdateGitLog(String)
    case UserInitiatedGitCommandResult(Either<Error, LowLevelProcessResult>)
    case UserInitiatedGitComandResultShowStatus(Either<Error, [LowLevelProcessResult]>)
    case CommandSuccess
    case Info(InfoMessage)
    case ClearInfo
    case QueryResult(QueryResult)
    case ViewFile(String)
    case DropBuffer
}

enum TerminalEvent {
    case Keyboard(KeyEvent)
    case Cursor(Cursor)
    case TerminalResize(Size)
}

enum GitCmd {
    case Status
    case GetCommit(String)
    case Stage(Selection)
    case Unstage(Selection)
    case Discard(Selection)
    case Stash(StashGitCommand)
}

enum StashGitCommand {
    case Both
    case Index
    case Worktree
    case Apply
    case Pop
}

enum QueryResult {
    case Abort
    case Perform(Message)
}

enum Selection {
    case Section([String], Status)
    case File(String, Status)
    case Hunk(String, Status)
}

enum Status {
    case Untracked
    case Unstaged
    case Staged
}

enum GitResult {
    case GotStatus(AsyncData<StatusInfo>)
    case GotLog(AsyncData<LogInfo>)
    case GotCommit(String, AsyncData<CommitInfo>)
}

enum Action {
    case Log
    case GitLog
    case Refresh
    case Commit
    case AmendCommit
    case Push
    case Pull
}

enum StashType {
    case Both
}
