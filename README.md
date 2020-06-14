# goose

**So alpha it hurts. This is just a toy right now, so please don’t use it for anything serious. Let me be the one destroying my
git repos, not you.**

Goose is a git client for your terminal. It is highly inspired by the best git client ever created – magit. It strives to be more
or less identical, with the only difference being that it lives in your terminal, and not in your Emacs.

## Rationale
[Magit](https://magit.vc) is probably the best git client/porcelain around. My only problem is that it lives inside Emacs,
and even though I really enjoy using Emacs I don’t like being tied to one single tool for all my tasks. Hence, I try to move
the best git client out of the best code editor and make it stand alone.

What could possibly go wrong.

## Status

Working
- Untracked files, worktree changes and index changes as diff
- Stage section / file / hunk
- Unstage section / file / hunk
- Discard section / file / hunk
- Commiting
- Listing log
- UI: Information line
- UI: scrolling
- Open file under cursor

Next up (far from exhaustive, just a short list of possible next tasks..)
- Window resizing
- Better git error handling
- Git input/output log for debugging
- Async tasks so we don’t block rendering
- Transient command system (aka the Magit menu system)
- Amend commit
- Search in active buffer to quickly move around
- See commit content
- Optimizations
- Stage / unstage /discard lines
- ... soooo much more

Bugs
- Diffs with tab characters (and possibly others) breaks rendering

## Instructions

- Run: `swift run`
- Build debug: `make debug`
- Build production: `make build`
- Install: `make install`
- Uninstall: `make uninstall`
- Clean: `make clean`

## Attribution

The [tea library](libraries/tea) is inspired (and some stuff copied) from [Ashen](https://github.com/colinta/Ashen).
