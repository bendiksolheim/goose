    public static func files() -> GitCommand {
    public static func index() -> GitCommand {
        GitCommand(
            arguments: ["diff-index", "--cached", "--patch", "--no-color", "HEAD"]
        )
    }
    
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.header.append(line)
            diff[currentFile]?.add(hunk: currentHunk)
        } else {
            diff[currentFile]?[currentHunk]?.append(line: line)
    subscript(key: String) -> GFile? {
            files[key]