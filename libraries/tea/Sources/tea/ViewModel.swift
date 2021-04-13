import Foundation

public struct ViewModel<Message, Data> {
    let view: [Line<Message>?]
    public let data: Data
    
    public init(_ view: [Line<Message>?], _ data: Data) {
        self.view = view
        self.data = data
    }
}
