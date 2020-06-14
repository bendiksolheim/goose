import Foundation
import os.log

struct Matrix<T> {
    let rows: Int
    let columns: Int
    var grid: [T]
    
    init(rows: Int, columns: Int, defaultValue: T) {
        self.rows = rows
        self.columns = columns
        self.grid = Array(repeating: defaultValue, count: rows * columns)
    }
    
    init(rows: Int, columns: Int, grid: [T]) {
        self.rows = rows
        self.columns = columns
        self.grid = grid
    }
    
    subscript(row: Int, column: Int) -> T {
        get {
            return grid[row * columns + column]
        }
        set(newValue) {
            grid[row * columns + column] = newValue
        }
    }
    
    subscript(rect: Rect) -> Matrix<T> {
        get {
            var subMatrix = Matrix(rows: rect.height, columns: rect.width, defaultValue: self[rect.y, rect.x])
            for row in 0..<rect.height {
                for col in 0..<rect.width {
                    subMatrix[row, col] = self[row + rect.y, col + rect.x]
                }
            }
            return subMatrix
        }
    }
    
    mutating func replaceRect(_ rect: Rect, with replacement: [T]) {
        for row in 0 ..< rect.height {
            let replaceRange = (rect.y * self.columns + row * self.columns + rect.x) ..< (rect.y * self.columns + row * self.columns + rect.x + rect.width)
            let replacementRange = row * rect.width ..< (row * rect.width + rect.width)
            grid.replaceSubrange(replaceRange, with: replacement[replacementRange])
        }
    }
}

func map<T, U>(_ matrix: Matrix<T>, _ transform: (T) -> U) -> Matrix<U> {
    let mappedGrid: [U] = matrix.grid.map(transform)
    return Matrix(rows: matrix.rows, columns: matrix.columns, grid: mappedGrid)
}
