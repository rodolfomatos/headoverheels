---
id: T094
status: open
severity: minor
found_by: aes-peer-review/2026-10-02-input-and-model (utilizador)
---

# T094 — the keyboard dies silently if focus moves, and nothing says it exists

## Statement

`_KeyboardControls` requests focus in `initState`. On the game screen it is the only
focusable thing, so it works. If anything ever takes focus — a dialog, a route, the
pause overlay — a player holding the right arrow gets nothing, with no indication
that the key was received.

And there is no key hint anywhere in the HUD, so a player who does not already know
to try the arrow keys never learns they work. The game has had a keyboard for one
commit.

## What closing it needs

- The HUD says the keys. Six glyphs and no new screen.
- Focus loss is visible, or the controls are not focus-dependent. The second is
  better: a global key handler that does not care who holds focus removes the
  failure mode rather than reporting it.
