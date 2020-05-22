import Foundation
import tea

enum Views {
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
    let views: [Views]
    let status: StatusModel
    let log: AsyncData<LogInfo>
    let info: String
    let container: ScrollState
    
    func copy(withViews views: [Views]? = nil,
              withStatus status: StatusModel? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withInfo info: String? = nil,
              withContainer container: ScrollState? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              info: info ?? self.info,
              container: container ?? self.container
        )
    }
    
    func pushView(view: Views) -> Model {
        copy(withViews: self.views + [view])
    }
    
    func popView() -> Model {
        copy(withViews: self.views.dropLast())
    }
}
