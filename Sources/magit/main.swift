import Darwin
import Ashen


let app = App(program: Magit(), screen: TermboxScreen())
let exitState = app.run()

switch exitState {
case .quit: exit(EX_OK)
case .error: exit(EX_IOERR)
}

