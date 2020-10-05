import XCTest
@testable import GitLib

final class DiffParseTests: XCTestCase {
    let git = Git(path: "")
    
    func testParseDiff() {
        let diff = git.diff.parse(diffOne)
        let files = diff.files.map { $0.source }.sorted()
        let expected = [
            "a-folder/a-file.ts",
            "b-folder/b-file.ts"
        ].sorted()
        XCTAssertEqual(expected, files)
    }
    
    static var allTests = [
        ("parseDiff", testParseDiff),
    ]
}

let diffOne = """
diff --git a/a-folder/a-file.ts b/a-folder/a-file.ts
index c6f00a1..88521a5 100644
--- a/a-folder/a-file.ts
+++ b/a-folder/a-file.ts
@@ -117,6 +117,7 @@ function someFunction(e) {
     one: "hello",
     two: "hello",
     three: "hello",
+    four: "there",
     five: "hello",
     six: "hello",
     seven: "hello",
diff --git a/b-folder/b-file.ts b/b-folder/b-file.ts
index c6f00a1..88521a5 100644
--- a/b-folder/b-file.ts
+++ b/b-folder/b-file.ts
@@ -117,6 +117,7 @@ function someFunction(e) {
     one: "hello",
     two: "hello",
     three: "hello",
+    four: "there",
     five: "hello",
     six: "hello",
     seven: "hello",
"""
