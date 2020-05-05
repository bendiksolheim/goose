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
- Staging
- Unstaging
- Diffing file
- Commiting
- Listing log
- UI: Information line

Next up
- UI: scrolling
- Stage / unstage hunks and lines
- Async tasks so we don’t block rendering
- Discard change
- Transient command system
- Amend commit
- Search in active buffer to quickly move around
- Optimization
- ... soooo much more

## Instructions

- Run: `swift run`
- Build debug: `swift build`
- Build production: `swift build -c release`
