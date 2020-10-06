struct GitLogModel: Equatable {
    let history: [GitLogEntry]
    
    init() {
        history = []
    }
    
    private init(_ history: [GitLogEntry]) {
        self.history = history
    }
    
    func append(_ entry: [GitLogEntry]) -> GitLogModel {
        GitLogModel(history + entry)
    }
}

struct GitLogEntry: Equatable {
    let timestamp: Int
    let command: String
    let result: String
    let success: Bool
    
    init(_ processResult: ProcessResult) {
        timestamp = processResult.timestamp
        command = processResult.command
        result = processResult.output
        success = processResult.success
    }
}
