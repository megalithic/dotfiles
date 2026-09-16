# Pi control web

Pi control web gives `megaphone` private, authenticated access to active Pi sessions on `workbookpro` through a loopback gateway, Tailscale Serve, and an installable PWA.

## Ownership and deployment

`config/pi-control-web/` owns the zero-dependency Node gateway, PWA files, smoke test, and operator README. The service is workbookpro-only.

`config/mise/config.workbookpro.toml` declares the `com.megadots.pi-control-web` LaunchAgent. Mise launches `mise/scripts/pi-control-web-launchd`, which resolves the managed Node binary and runs `server.mjs`. The gateway refuses bind addresses other than `127.0.0.1` and listens on port 8788 by default.

The canonical gateway token is the concealed `token` field in the Crypt vault's `pi-control-web` item. `config/fnox/shared.toml` declares it as the on-demand, non-exported `PI_CONTROL_WEB_TOKEN`; `mise run update:fnox` copies it into the encrypted local cache. `mise run setup:pi-control-web` resolves that cached value, rejects short or missing values, and atomically materializes `~/.config/pi-control-web/token` with mode `0600`. It also creates `~/Library/Logs/pi-control-web/` before launchd opens its log files.

Tailscale Serve proxies tailnet HTTPS to the loopback port. Serve routes and tailnet grants are machine and control-plane state, not repo-owned configuration. `config/pi-control-web/README.md` documents the Serve command, commands that derive current node addresses, and an ACL template with address placeholders. Tailscale node addresses survive ordinary network and public-IP changes but may change when a node is deleted and recreated; live status and the control plane remain authoritative. Optional 1Password address fields are inventory only. The repository stores no device address or tailnet domain. Because grants are additive, operators must remove or narrow broader overlapping rules before treating the route as exclusive to `megaphone`. Tailscale installation ownership remains in [[lat.md/system-config#Tailscale GUI app]], and host bootstrap behavior is described in [[lat.md/architecture#Mise bootstrap]].

## Gateway request flow

The gateway translates authenticated HTTP requests into the existing `pi.control.v1` Unix-socket protocol documented in [[lat.md/programs/pi-coding-agent#Session and routing extensions]]. It never starts a Pi process or writes directly to a Pi session.

For each request, the gateway reads non-ephemeral manifests from `$PI_STATE_DIR/manifests`, verifies that each path names a live Unix socket, asks one reachable bridge for `sessions.list`, and accepts only returned sockets that appeared in the manifest scan. Public responses replace socket paths and logical Pi IDs with token-keyed HMAC route IDs. They expose only the session name, project basename, tmux coordinates, activity state, and timestamps. Bridge transport failures return generic HTTP errors so local paths stay private.

The bridge protects this path with mode-`0700` socket and manifest directories, mode-`0600` socket files, ownership and inode checks, and a 1 MiB client receive-buffer limit. Its manifests publish `idle`, `working`, `input_needed`, `done`, or `error`. Input and agent start set `working`; structured prompts temporarily set `input_needed` and restore their prior state when they close; `agent_settled` publishes the final state; logical session switches reset to `idle`.

## Authentication and HTTP boundary

A Crypt-backed 256-bit token authenticates the first login and becomes a derived, secure browser cookie.

The server compares secrets in constant time and sets the derived cookie as `HttpOnly; Secure; SameSite=Strict`. The raw token never enters a URL, PWA manifest, service-worker cache, or browser storage.

Cookie-authenticated mutations require a same-host `Origin`. Bearer-authenticated non-browser clients may omit it. The server sets a restrictive content security policy, denies framing, sends API responses with `Cache-Control: no-store`, enables no CORS policy, caps JSON bodies and message length, and accepts only `steer` or `follow_up` delivery modes.

The HTTP surface is:

- `GET /healthz`
- `POST /api/login` and `POST /api/logout`
- `GET /api/sessions`
- `GET /api/sessions/:id/last`
- `POST /api/sessions/:id/messages`
- `GET /api/events`

## PWA and live status

`web/` is a no-build mobile interface. It lists active sessions, shows the latest assistant response, and sends explicit `steer` or `follow_up` input. It does not stream transcripts or model tokens.

The SSE endpoint reconciles session status every two seconds, sends heartbeat comments, and caps the gateway at eight concurrent streams. Gateway shutdown ends open streams before closing the HTTP server. The browser guards session-detail requests against stale responses after navigation.

The service worker bypasses `/api/` requests. It uses `/` as the cache key for navigation responses, so deep-link query IDs do not become cache keys. Push-display and notification-click handlers accept a future opaque session ID and open the matching session view. Subscription storage, VAPID key management, and push delivery remain deferred.

## Validation and rollout

The gateway smoke test covers the HTTP-to-bridge path, while colocated Bun tests cover notifications and bridge activity state.

`config/pi-control-web/smoke-test.mjs` starts a mock `pi.control.v1` socket and an ephemeral gateway. It checks authentication, response sanitization, latest-message reads, both send modes, SSE snapshots, and shutdown with an open SSE client. Notification and bridge-state tests live under `config/pi-coding-agent/tests/`.

The LaunchAgent and Tailscale Serve route can be validated locally, but final rollout still requires two external checks: apply and inspect the central tailnet policy, then verify login, session reads, both delivery modes, live status, and Home Screen installation from `megaphone`. Existing Pi processes must restart before they load changed extension code.
