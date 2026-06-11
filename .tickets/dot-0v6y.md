---
id: dot-0v6y
status: open
deps: 4:1:deps: [, dot-satx]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Enforce Pi-side strict pair claim rules

Make pinvim.ts runtime pair state the ownership authority. File hints: home/common/programs/pi-coding-agent/extensions/pinvim.ts (PeerIdentity, peerAllowedForSocket, hello/heartbeat handling, acceptedSockets, state.lastHello/state.lastHeartbeat). Add pairId and 20s stale/dead claim rules.

## Acceptance Criteria

1. Exact pairId hello is accepted
2. Live mismatched pairId is rejected with a visible reason, even from same tmux window
3. Same tmux session+window can claim only when Pi is unpaired, paired Nvim is dead, or heartbeat is stale for more than 20s
4. Non-tmux peers are accepted only by exact pairId or explicit target mode
5. Heartbeats before accepted hello remain rejected
6. Existing pinvim behavior still validates with devenv shell -- just validate home
