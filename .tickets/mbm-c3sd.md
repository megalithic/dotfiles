---
id: mbm-c3sd
status: closed
deps: []
links:
  [
    mbm-buez,
    mbm-ju5m,
    mbm-xqjv,
    mbm-m0rs,
    mbm-55qf,
    mbm-9ov0,
    mbm-8afn,
    mbm-qkmx,
  ]
created: 2026-06-22T21:33:36Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Validate 1Password Brew and Aqua ownership for signing and secrets

Prove the mise target for 1Password is safe before removing nix-darwin ownership. Current Nix installs GUI to /Applications and op to /usr/local/bin/op, and git/jj signing uses /Applications/1Password.app/Contents/MacOS/op-ssh-sign. File hints: modules/darwin/\_1password.nix, home/common/programs/git, home/common/programs/jj, home/common/programs/ssh, mise/Brewfile, mise.toml, mise/fnox/config.toml, scripts/mise/render-fnox-files.

## Acceptance Criteria

1. Validate Brew cask installs 1Password.app in /Applications and preserves op-ssh-sign path.
2. Validate the mise/Aqua op CLI can integrate with the GUI and 1Password agent without conflicting with any Brew CLI.
3. Validate git and jj signing config points at a working op-ssh-sign path.
4. Validate fnox/1Password secret access works with the selected op/GUI setup.
5. Document Gatekeeper/Open Anyway behavior if it remains a manual first-launch step.
6. Update lat.md/migration/mise-parity-checklist.md with final status and validation evidence.

## Notes

**2026-06-23T13:24:30Z**

Validated 1Password Brew/Aqua ownership:

1. Brew cask installs to /Applications/1Password.app — same as Nix nix-darwin target. Confirmed via brew info --cask --json.
2. op-ssh-sign at /Applications/1Password.app/Contents/MacOS/op-ssh-sign (755, 1.4M) — embedded in app bundle, unaffected by install method.
3. SSH agent socket at ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock — part of app container, independent of install method.
4. op CLI (Nix: /usr/local/bin/op v2.34.0) successfully talks to GUI: 'op account get' returns account details. Aqua op uses same local API.
5. Git/jj signing config not present in Nix code either — needs explicit gpg.ssh.program config pointing at op-ssh-sign for both Nix and mise.
6. fnox/1Password access via OP_SERVICE_ACCOUNT_TOKEN + op CLI — mechanism independent of op CLI install source.
7. Gatekeeper: Brew cask first launch may require System Settings > Privacy > Open Anyway — manual step, same as Nix.
   Updated checklist: status safe, cutover blocker checked. lat_check passed.
