import Foundation
import tea

func renderCommit(commit: CommitModel) -> [View<Message>] {
    switch commit.commit {
    case .loading:
        return [TextView("Loading...")]
        
    case .error(let error):
        return [TextView("Error: \(error.localizedDescription)")]
        
    case .success(let commit):
        var views: [View<Message>] = []
        views.append(TextView(Text("Commit \(commit.hash.short)", .white, .blue)))
        views.append(TextView(Text(commit.hash.full, .any(240))))
        views.append(TextView("Author:     \(commit.author) \(commit.email)"))
        views.append(TextView("AuthorDate: \(commit.authorDate.format(commitDateFormat))"))
        views.append(TextView("Commit:     \(commit.author) \(commit.email)")) //TODO: need to parse committer
        views.append(TextView("CommitDate: \(commit.commitDate)"))
        views.append(EmptyLine())
        views.append(TextView("Parent      \(commit.parents[0])"))
        
        return views
    }
}

private let commitDateFormat = "E MMM dd HH:mm:ss yyyy Z"
