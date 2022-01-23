import Foundation
import Slowbox

public protocol TextType {
    func terminalContent() -> [(Formatting, Character)]
}

public struct Text: TextType {
    public let content: [(Formatting, Character)]
    
    public init(_ content: String, _ foreground: Color = .Default, _ background: Color = .Default) {
        self.content = Array(content).map { (Formatting(foreground, background), $0)}
    }
    
    init(_ content: [(Formatting, Character)]) {
        self.content = content
    }
    
    public func terminalContent() -> [(Formatting, Character)] {
        return content
    }
}

extension String: TextType {
    public var content: [(Formatting, Character)] {
        Array(self).map { (Formatting(.Default, .Default), $0)}
    }
    
    public func terminalContent() -> [(Formatting, Character)] {
        return Array(self).map { (Formatting(.Default, .Default), $0)}
    }
}

public func + (lhs: Text, rhs: String) -> Text {
    return Text(lhs.content + rhs.content)
}

public func + (lhs: String, rhs: Text) -> Text {
    return Text(lhs.content + rhs.content)
}

public func + (lhs: Text, rhs: Text) -> Text {
    return Text(lhs.content + rhs.content)
}
