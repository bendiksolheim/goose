
public struct Rectangle: Equatable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    
    public static func empty() -> Rectangle {
        return Rectangle(x: 0, y: 0, width: 0, height: 0)
    }
    
    public func withX(_ x: Int) -> Rectangle {
        return Rectangle(x: x, y: y, width: width, height: height)
    }
    
    public func withY(_ y: Int) -> Rectangle {
        return Rectangle(x: x, y: y, width: width, height: height)
    }
    
    public func withWidth(_ width: Int) -> Rectangle {
        return Rectangle(x: x, y: y, width: width, height: height)
    }
    
    public func withHeight(_ height: Int) -> Rectangle {
        return Rectangle(x: x, y: y, width: width, height: height)
    }
}
