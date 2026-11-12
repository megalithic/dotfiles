Reports each Ultimate instance's busy or waiting-for-answer state on its own Rex tab.

Loaded as a user extension from `~/.ultimate/extensions/rex-status/`. Without
`REX_BLOCK` it does nothing. Otherwise it polls the in-process `status` action
every three seconds: open questions are `blocked` (one line, up to 120 characters),
busy conversations are `working`, and everything else is `idle`.

Changes emit OSC 7501 for `app=ultimate` to `/dev/tty`, with base64 messages.
Terminal write errors are harmless. Facet-scoped lifecycle callbacks stop the
timer and reset to `idle` on reload, disable, unload, or shutdown.
