Reports each Ultimate instance's busy or waiting-for-answer state on its own Rex tab.

Loaded as a user extension from `~/.ultimate/extensions/rex-status/`. Without
`REX_BLOCK` it does nothing. Otherwise it polls the in-process `status` action
every three seconds and reads the `inbox-items.items` document. What waits on the user is
open questions plus open Inbox items, the same count as `rtm needs` and the Inbox badge:
any is `blocked` with `msg` "N waiting · <first question>" (up to 120 characters, with
`kind=question` while a question is open), busy conversations are `working`, and
everything else is `idle`.

Changes emit OSC 7501 for `app=ultimate` to `/dev/tty`, with base64 messages.
Terminal write errors are harmless. Facet-scoped lifecycle callbacks stop the
timer and reset to `idle` on reload, disable, unload, or shutdown.

## Reload

After a change lands, compare this extension's `server.loadedAt` in `ultimate.extensions()` with the commit time; restart the host only if it did not reload.
