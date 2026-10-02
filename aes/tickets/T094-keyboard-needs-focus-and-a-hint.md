---
id: T094
status: done
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

## Closed: the failure mode removed, and the keys said out loud

**The keyboard no longer depends on focus.** `HardwareKeyboard.instance.addHandler`
instead of a `Focus` widget. A `Focus` only sees a key while it holds the focus,
and the keyboard worked because this screen happened to be the only focusable
thing — the moment anything else took focus, a player holding the right arrow
would have got nothing with no indication the key was received. A hardware handler
cannot be taken away, so the failure mode is gone rather than reported.

There is a re-entrancy guard on the handler: the widget also receives key events
through the focused subtree on platforms that route both, and handling a jump
twice is worse than handling it once.

**The HUD says the keys.** `arrows / WASD move`, `space / Z jump`, `X / C carry`,
`V / F fire`, `tab / Q swop`, at the bottom of the screen. Five pairs of glyphs and
no new screen. A feature nobody can discover is a feature with no users, and the
keyboard had existed for one commit with nothing on screen to say so.

## What this does not settle

Whether those are the right bindings. They are conventional and they are written
down, and a player learns them in the first ten seconds; whether the game wants
`Z` to jump or `E` is a question for whoever plays it.
