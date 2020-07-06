import Bow
import Foundation
import tea

func renderCommit(commit: CommitModel) -> [View<Message>] {
    switch commit.commit {
    case .Loading:
        return [TextView("Loading...")]

    case let .Error(error):
        return [TextView("Error: \(error.localizedDescription)")]

    case let .Success(commit):
        var views: [View<Message>] = []
        views.append(TextView(Text("Commit \(commit.hash.short)", .White, .Blue)))
        views.append(TextView(Text(commit.hash.full, .Custom(240))))
        views.append(TextView("Author:     \(commit.author) \(commit.email)"))
        views.append(TextView("AuthorDate: \(commit.authorDate.format(commitDateFormat))"))
        views.append(TextView("Commit:     \(commit.author) \(commit.email)")) // TODO: need to parse committer
        views.append(TextView("CommitDate: \(commit.commitDate)"))
        views.append(EmptyLine())
        views.append(TextView("Parent      \(commit.parents[0])"))
        views.append(EmptyLine())
        
        views.append(TextView(Text(commit.message, .White, .Magenta)))
        views.append(EmptyLine())
        
        views.append(contentsOf:
            commit.diff.map { diff in
                diff.files.flatMap { file in
                    file.hunks.flatMap { hunk in
                        mapHunks(hunk, .Staged)
                    }
                }
            }
            .combineAll()
        )

        return views
    }
}

private let commitDateFormat = "E MMM dd HH:mm:ss yyyy Z"
