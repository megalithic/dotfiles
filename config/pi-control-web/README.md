# Pi control web

Pi control web is a loopback-only gateway and mobile PWA for active terminal Pi sessions. It translates authenticated HTTP requests into the existing `pi.control.v1` Unix-socket protocol. It does not start agents or route messages outside that protocol.

## Current slice

The PWA can:

- list reachable, non-ephemeral Pi bridge sessions;
- show each session's `idle`, `working`, `input_needed`, `done`, or `error` state;
- fetch the latest assistant response;
- send `steer` or `follow_up` input;
- receive session-list and status changes through server-sent events;
- install from Safari as an iOS Home Screen app.

The service worker includes `push` and `notificationclick` handlers. A future Web Push backend can send `{ "title", "body", "sessionId" }`; notification clicks already open `/?session=<opaque-id>`. Push subscription storage, VAPID keys, and push delivery are not implemented yet.

## Security

- The server rejects any bind address except `127.0.0.1`.
- The canonical 256-bit token lives in the Crypt vault at `pi-control-web/token`; fnox caches it and the setup task materializes it at `~/.config/pi-control-web/token` with mode `0600`.
- Login compares the token in constant time and exchanges it for a derived `HttpOnly; Secure; SameSite=Strict` cookie.
- API responses expose opaque session IDs, project basenames, tmux coordinates, and status. They do not expose Unix socket paths, PIDs, owner tokens, or full working-directory paths.
- State-changing requests validate `Origin`. The server enables no CORS policy.
- Tailscale Serve and its access policy form a second boundary. They do not replace the application token.

## Local setup

On `workbookpro`:

```sh
mise run update:fnox
mise run setup:pi-control-web
MISE_ENV=workbookpro mise bootstrap macos launchd-agents apply --yes
launchctl print "gui/$(id -u)/dev.mise.com.megadots.pi-control-web"
curl -fsS http://127.0.0.1:8788/healthz
```

Copy the login token without printing it in shell history:

```sh
pbcopy < ~/.config/pi-control-web/token
```

Paste it once into the PWA login form. The PWA does not store the token in JavaScript storage.

For a foreground development run:

```sh
mise exec node -- node config/pi-control-web/server.mjs
```

## Tailscale Serve

First inspect existing Serve routes. Do not use `tailscale serve reset`, because it removes unrelated routes:

```sh
tailscale serve status
tailscale serve --bg 8788
tailscale serve status
```

The second command exposes `http://127.0.0.1:8788` at the workstation's private tailnet HTTPS name. Tailscale prompts to enable MagicDNS and HTTPS certificates if the tailnet does not already provide them. Use Serve, not Funnel; Funnel is public.

Get the resulting URL with:

```sh
printf 'https://%s\n' "$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')"
```

Open that URL in Safari on `megaphone`, sign in, then use Share > Add to Home Screen.

## Tailnet grant for `megaphone`

Do not apply a policy blindly. Read the current Tailscale IPv4 addresses from the admin console or derive them locally without storing them in Git:

```sh
tailscale ip -4
tailscale status --json | jq -r '.Peer[] | select((.DNSName // "") | startswith("megaphone.")) | .TailscaleIPs[] | select(startswith("100."))'
```

A Tailscale `100.x` address stays stable when a device changes Wi-Fi, cellular networks, or public IP addresses. It can change when a node is deleted and re-added, recreated, or moved to another tailnet. Treat the live Tailscale status and control plane as authoritative; optional 1Password address fields are private inventory, not runtime configuration. Merge the current addresses into aliases and this grant:

```jsonc
{
  "hosts": {
    "megaphone": "<MEGAPHONE_TAILSCALE_IPV4>",
    "workbookpro": "<WORKBOOKPRO_TAILSCALE_IPV4>"
  },
  "grants": [
    {
      "src": ["megaphone"],
      "dst": ["workbookpro"],
      "ip": ["tcp:443"]
    }
  ],
  "tests": [
    {
      "src": "megaphone",
      "accept": ["workbookpro:443"]
    }
  ]
}
```

If either node is recreated, update its host alias in the central policy. Grants are additive. A broad existing rule such as `src: ["*"]` to `workbookpro` or port 443 still permits other devices. Narrow or remove every overlapping broad rule before treating this grant as an exclusive restriction. Save the policy in the Tailscale admin console and confirm its policy tests pass. This repository does not edit the tailnet policy.

## API

```text
GET  /healthz
POST /api/login
POST /api/logout
GET  /api/sessions
GET  /api/sessions/:id/last
POST /api/sessions/:id/messages
GET  /api/events
```

`/api/sessions/:id/messages` accepts JSON with non-empty `text` and `mode` set to `steer` or `follow_up`. The SSE endpoint sends `snapshot` events and 15-second heartbeat comments. It reconciles with the bridge every two seconds; it is status polling, not transcript or token streaming.

## Validation

```sh
mise exec node -- node --check config/pi-control-web/server.mjs
mise exec node -- node config/pi-control-web/smoke-test.mjs
```
