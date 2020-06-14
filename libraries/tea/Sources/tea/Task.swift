import Foundation

enum TaskType {
    case Internal
    case External
}

public struct Task<R> {
    let task: () -> R
    let type: TaskType
    
    public init(_ task: @escaping () -> R) {
        self.task = task
        self.type = .Internal
    }
    
    init(_ task: @escaping () -> R, _ taskType: TaskType) {
        self.task = task
        self.type = taskType
    }
    
    public func perform<Msg>(_ toMessage: @escaping (R) -> Msg) -> Cmd<Msg> {
        switch type {
        case .External:
            return Cmd(.Process {
                let result = self.task()
                return toMessage(result)
            })
        case .Internal:
            return Cmd(.Task {
                let result = self.task()
                return toMessage(result)
            })
        }
    }
    
    public func perform() -> Cmd<R> {
        self.perform { $0 }
    }
    
    public func andThen<R2>(_ task: @escaping (R) -> R2) -> Task<R2> {
        Task<R2> {
            let r = self.task()
            let t = task(r)
            return t
        }
    }
}
