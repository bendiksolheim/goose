import Foundation

enum TaskType {
    case Internal
    case External
}

enum Sync {
    case Sync
    case Async(TimeInterval)
}

public struct Task<R> {
    let task: () -> R
    let type: TaskType
    let sync: Sync

    public init(_ task: @escaping () -> R) {
        self.task = task
        type = .Internal
        self.sync = .Sync
    }

    init(_ task: @escaping () -> R, _ taskType: TaskType) {
        self.task = task
        type = taskType
        sync = .Sync
    }
    
    init(_ task: @escaping () -> R, _ sync: Sync) {
        self.task = task
        type = .Internal
        self.sync = sync
    }

    public func perform<Msg>(_ toMessage: @escaping (R) -> Msg) -> Cmd<Msg> {
        switch type {
        case .External:
            return Cmd(.Process {
                let result = self.task()
                return toMessage(result)
            })
        case .Internal:
            switch sync {
            case .Sync:
                return Cmd(.Task {
                    let result = self.task()
                    return toMessage(result)
                })
            case let .Async(delay):
                return Cmd(.AsyncTask(delay) {
                    let result = self.task()
                    return toMessage(result)
                })
            }
        }
    }

    public func perform() -> Cmd<R> {
        perform { $0 }
    }

    public func andThen<R2>(_ task: @escaping (R) -> R2) -> Task<R2> {
        Task<R2> {
            let r = self.task()
            let t = task(r)
            return t
        }
    }
    
    public func andThen<R2>(_ task: Task<R2>) -> Task<R2> {
        Task<R2> {
            let _ = self.task()
            return task.task()
        }
    }
    
    public static func sequence(_ tasks: [Task<R>]) -> Task<[R]> {
        Task<[R]> {
            return tasks.map { $0.task() }
        }
    }
}
