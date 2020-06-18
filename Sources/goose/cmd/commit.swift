import BowEffects
import Foundation
import GitLib
import os.log

// https://gist.github.com/dduan/d4e967f3fc2801d3736b726cd34446bc

func runCommand(_ command: String) -> Int {
    var pid: pid_t = 0
    let args = ["sh", "-c", command]
    let envs = ProcessInfo().environment.map { k, v in "\(k)=\(v)" }
    let cArgs = args.map { strdup($0) } + [nil]
    let cEnvs = envs.map { strdup($0) } + [nil]

    var status = posix_spawn(&pid, "/bin/sh", nil, nil, cArgs, cEnvs)
    cEnvs.forEach { free($0) }
    cArgs.forEach { free($0) }

    os_log("posix_spawn return for pid %{public}d: %{public}d", Int(pid), Int(status))
    var returnStatus = -1
    let rc = waitpid(pid, &status, 0)
    if rc == -1 {
        let error = POSIXErrorCode(rawValue: errno)
        switch error {
        case .ECHILD:
            os_log("ECHILD")
        case .EDEADLK:
            os_log("EDEADLK")
        default:
            if let _error = error {
                os_log("%{public}@", "\(_error.rawValue)")
            } else {
                os_log("Unknown error")
            }
        }
    } else {
        if rc != pid {
            os_log("waitpid returned wrong pid?")
        } else if WIFEXITED(status) { // Normal exit
            os_log("Normal exit with status code %{public}d", Int(WEXITSTATUS(status)))
            returnStatus = Int(WEXITSTATUS(status))
        } else if WIFSIGNALED(status) {
            os_log("Terminated due to signal: %{public}d", Int(WTERMSIG(status)))
        } else if WIFSTOPPED(status) {
            os_log("Process stopped, can be restarted: %{public}d", Int(WSTOPSIG(status)))
        }
    }

    return returnStatus
}

func _WSTATUS(_ x: CInt) -> CInt { x & 0x7F }
func WSTOPSIG(_ x: CInt) -> CInt { x >> 8 }
func WIFEXITED(_ x: CInt) -> Bool { _WSTATUS(x) == 0 }

func WIFSTOPPED(_ x: CInt) -> Bool {
    _WSTATUS(x) == 0x7F && WSTOPSIG(x) != 0x13
}

func WIFSIGNALED(_ x: CInt) -> Bool {
    _WSTATUS(x) != 0x7F && _WSTATUS(x) != 0
}

func WEXITSTATUS(_ x: CInt) -> CInt { (x >> 8) & 0xFF }
func WTERMSIG(_ x: CInt) -> CInt { _WSTATUS(x) }

private func currentDirectory() -> String {
    FileManager.default.currentDirectoryPath
}
