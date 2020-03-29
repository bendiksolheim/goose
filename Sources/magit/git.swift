//
//  git.swift
//  magit
//
//  Created by Bendik Solheim on 28/03/2020.
//

private let git = "/usr/local/bin/git"

func branchName() -> String {
    let branchName = run(cmd: git, args: "symbolic-ref", "--short", "HEAD")
    return branchName ?? ""
}

