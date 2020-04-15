import Foundation

enum View {
    case status
    case log
}

struct CursorModel: Equatable {
    let x: UInt
    let y: UInt
    
    init(_ x: UInt, _ y: UInt) {
        self.x = x
        self.y = y
    }
}

struct Model: Equatable {
    let views: [View]
    let status: AsyncData<StatusInfo>
    let log: AsyncData<LogInfo>
    let cursor: CursorModel
    
    func copy(withViews views: [View]? = nil,
              withStatus status: AsyncData<StatusInfo>? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withCursor cursor: CursorModel? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              cursor: cursor ?? self.cursor)
    }
    
    func pushView(view: View) -> Model {
        copy(withViews: self.views + [view])
    }
    
    func popView() -> Model {
        copy(withViews: self.views.dropLast())
    }
}
