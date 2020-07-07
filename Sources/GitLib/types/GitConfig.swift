public struct GitConfig: Equatable {
    let config: [String: String]
    
    init(_ config: [String: String]) {
        self.config = config
    }
    
    public func string(_ key: String) -> String? {
        return config[key]
    }
    
    public func string(_ key: String, default _default: String) -> String {
        let stringValue = config[key, default: _default]
        return stringValue
    }
    
    public func bool(_ key: String, default _default: Bool) -> Bool {
        let value = config[key, default: ""]
        let boolValue = Bool.init(value) ?? _default
        return boolValue
    }
}
