import Foundation

public struct Rect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    init(_ x: Int, _ y: Int, _ width: Int, _ height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
