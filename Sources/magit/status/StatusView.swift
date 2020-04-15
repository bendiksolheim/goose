//
//  StatusView.swift
//  magit
//
//  Created by Bendik Solheim on 10/04/2020.
//

import Foundation
/*import Ashen
import GitLib
import Bow

func renderStatus(status: AsyncData<StatusInfo>, screenSize: Size) -> [Component] {
    switch status {
    case .loading:
        return [LabelView(at: .topLeft(), text: "Loading...")]
    case .error(let error):
        return [LabelView(at: .topLeft(), text: error.localizedDescription)]
    case .success(let status):
        var sections: [Component] = [Section(title: headMapper(status.log[0]), items: [], open: true)]
        
        let untracked = status.changes.filter(isUntracked)
        if untracked.count > 0 {
            sections.append(Section(title: fileStatusTitle("Untracked files (\(untracked.count))"), items: untracked.map(changeMapper), open: true))
        }

        let unstaged = status.changes.filter(isUnstaged)
        if unstaged.count > 0 {
            sections.append(Section(title: fileStatusTitle("Unstaged changes (\(unstaged.count))"), items: unstaged.map(changeMapper), open: true))
        }

        let staged = status.changes.filter(isStaged)
        if staged.count > 0 {
            sections.append(Section(title: fileStatusTitle("Staged changes (\(staged.count))"), items: staged.map(changeMapper), open: true))
        }

        sections.append(Section(title: LabelView(text: "Recent commits"), items: status.log.map(commitMapper), open: true))

        return [
            FlowLayout.vertical(size: DesiredSize(width: screenSize.width, height: screenSize.height), components: sections)
        ]
    }
}

func fileStatusTitle(_ title: String) -> LabelView {
    LabelView(text: Text(title, [.foreground(.blue)]))
}

func headMapper(_ commit: GitCommit) -> LabelView {
    let ref = commit.refName.getOrElse("")
    return LabelView(text: "Head:     " + Text(ref, [.foreground(.cyan)]) + " " + commit.message)
}

func commitMapper(_ commit: GitCommit) -> LabelView {
    let message = commit.refName
        .fold(constant(Text(" ")), { name in Text(" \(name) ", [.foreground(.cyan)]) }) + commit.message
    return LabelView(text: Text(commit.hash.short, [.foreground(.any(241))]) + message)
}

func changeMapper(_ change: Change) -> LabelView {
    switch change.status {
    case .Added:
        return LabelView(text: "new file  \(change.file)")
    case .Untracked:
        return LabelView(text: change.file)
    case .Modified:
        return LabelView(text: "modified  \(change.file)")
    case .Deleted:
        return LabelView(text: "deleted  \(change.file)")
    case .Renamed:
        return LabelView(text: "renamed   \(change.file)")
    case .Copied:
        return LabelView(text: "copied    \(change.file)")
    }
}
*/
