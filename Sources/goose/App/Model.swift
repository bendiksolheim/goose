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
    let status: StatusModel
    let log: AsyncData<LogInfo>
    let cursor: CursorModel
    let info: String
    
    func copy(withViews views: [View]? = nil,
              withStatus status: StatusModel? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withCursor cursor: CursorModel? = nil,
              withInfo info: String? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              cursor: cursor ?? self.cursor,
              info: info ?? self.info              
        )
    }
    
    func pushView(view: View) -> Model {
        copy(withViews: self.views + [view])
    }
    
    func popView() -> Model {
        copy(withViews: self.views.dropLast())
    }
}
