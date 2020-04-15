//
//  StatusView.swift
//  magit
//
//  Created by Bendik Solheim on 10/04/2020.
//

import Foundation
import GitLib
import Bow

func renderStatus(status: AsyncData<StatusInfo>) -> [Line] {
    switch status {
    case .loading:
        return [Line("Loading...")]
    case .error(let error):
        return [Line(error.localizedDescription)]
    case .success(let status):
        var sections: [Line] = Section(title: headMapper(status.log[0]), items: [], open: true)
        
        let untracked = status.changes.filter(isUntracked)
        if untracked.count > 0 {
            sections.append(contentsOf: Section(title: fileStatusTitle("Untracked files (\(untracked.count))"), items: untracked.map(changeMapper), open: true))
        }

        let unstaged = status.changes.filter(isUnstaged)
        if unstaged.count > 0 {
            sections.append(contentsOf: Section(title: fileStatusTitle("Unstaged changes (\(unstaged.count))"), items: unstaged.map(changeMapper), open: true))
        }

        let staged = status.changes.filter(isStaged)
        if staged.count > 0 {
            sections.append(contentsOf: Section(title: fileStatusTitle("Staged changes (\(staged.count))"), items: staged.map(changeMapper), open: true))
        }

        sections.append(contentsOf: Section(title: Line("Recent commits"), items: status.log.map(commitMapper), open: true))

        return sections
    }
}

func fileStatusTitle(_ title: String) -> Line {
    Line(Text(title, [.foreground(.blue)]))
}

func headMapper(_ commit: GitCommit) -> Line {
    let ref = commit.refName.getOrElse("")
    return Line("Head:     " + Text(ref, [.foreground(.cyan)]) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> Line {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", [.foreground(.cyan)]) }) + commit.message
    return Line(Text(commit.hash.short, [.foreground(.any(241))]) + message)
}

func changeMapper(_ change: Change) -> Line {
    switch change.status {
    case .Added:
        return Line("new file  \(change.file)")
    case .Untracked:
        return Line(change.file)
    case .Modified:
        return Line("modified  \(change.file)")
    case .Deleted:
        return Line("deleted  \(change.file)")
    case .Renamed:
        return Line("renamed   \(change.file)")
    case .Copied:
        return Line("copied    \(change.file)")
    }
}

