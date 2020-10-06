struct GitLogModel: Equatable {
    let history: [GitLogEntry]
    let visibility: [String: Bool]
    
    init() {
        history = []
        visibility = [:]
    }
    
    private init(_ history: [GitLogEntry], _ visibility: [String : Bool]) {
        self.history = history
        self.visibility = visibility
    }
    
    func append(_ entry: [GitLogEntry]) -> GitLogModel {
        GitLogModel(history + entry, visibility)
    }
    
    func with(visibility: [String : Bool]?) -> GitLogModel {
        GitLogModel(history, visibility ?? self.visibility)
    }
    
    func toggle(file: String) -> GitLogModel {
        with(visibility: visibility.merging([file: !visibility[file, default: false]], uniquingKeysWith: { $1 }))
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
    
    func identifier() -> String {
        "\(timestamp)-\(command)"
    }
}
