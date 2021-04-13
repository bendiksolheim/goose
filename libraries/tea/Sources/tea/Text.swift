import Foundation
import TermSwift

public protocol TextType {
    var terminalRepresentation: String { get }
}

public struct Text: TextType {
    public let content: [(Formatting, String)]
    
    public init(_ content: String, _ foreground: Color = .Default, _ background: Color = .Default) {
        self.content = [(Formatting(foreground, background), content)]
    }
    
    init(_ content: [(Formatting, String)]) {
        self.content = content
    }
    
    public var terminalRepresentation: String {
        return content.map { part in part.0.description + part.1 }.joined()
    }
}

extension String: TextType {
    public var content: [(Formatting, String)] {
        [(Formatting(.Default, .Default), self)]
    }
    
    public var terminalRepresentation: String {
        return Formatting(.Default, .Default).description + self
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
