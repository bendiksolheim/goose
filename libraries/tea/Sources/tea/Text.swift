import Foundation
import TermSwift

public protocol TextType {
    var terminalRepresentation: String { get }
    func capTo(_ width: Int) -> TextType
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
    
    public func capTo(_ width: Int) -> TextType {
        let length = content.map { $0.1.count }.reduce(0, +)
        if length <= width {
            return self
        } else {
            return Text(content.reduce([]) { acc, cur in
                let lengthSoFar = acc.map { $0.1.count }.reduce(0, +)
                if lengthSoFar >= width {
                    return acc
                } else if lengthSoFar + cur.1.count > width {
                    return acc + [(cur.0, String(cur.1.prefix(upTo: cur.1.index(cur.1.startIndex, offsetBy: width - lengthSoFar))))]
                } else {
                    return acc + [cur]
                }
            })
        }
    }
}

extension String: TextType {
    public var content: [(Formatting, String)] {
        [(Formatting(.Default, .Default), self)]
    }
    
    public var terminalRepresentation: String {
        return Formatting(.Default, .Default).description + self
    }
    
    public func capTo(_ width: Int) -> TextType {
        if self.count <= width {
            return self
        } else {
            return String(self.prefix(upTo: self.index(self.startIndex, offsetBy: width)))
        }
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
