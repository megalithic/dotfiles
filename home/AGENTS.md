# home/ — Home-manager configuration

## Structure

- `common/` — Shared config for all hosts
- `megabookpro.nix` — Personal laptop overrides
- `rxbookpro.nix` — Work laptop overrides

## Package placement

- `home/common/packages.nix` — Most CLI/GUI tools
- `home/common/programs/*.nix` — Tools with config (bat, eza, jujutsu, fzf)
- `hosts/common.nix` — Minimal system essentials
- `modules/brew.nix` — macOS apps needing special install

If `programs.X.enable = true`, do NOT also add to `environment.systemPackages`.

## Rebuilding

- Full: `just rebuild`
- HM only: `just rebuild-user` (no sudo)
- Darwin only: `just rebuild-system`
