import Foundation
import tea

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
    let info: String
    let container: ContainerState
    
    func copy(withViews views: [View]? = nil,
              withStatus status: StatusModel? = nil,
              withLog log: AsyncData<LogInfo>? = nil,
              withInfo info: String? = nil,
              withContainer container: ContainerState? = nil) -> Model {
        Model(views: views ?? self.views,
              status: status ?? self.status,
              log: log ?? self.log,
              info: info ?? self.info,
              container: container ?? self.container
        )
    }
    
    func pushView(view: View) -> Model {
        copy(withViews: self.views + [view])
    }
    
    func popView() -> Model {
        copy(withViews: self.views.dropLast())
    }
}
