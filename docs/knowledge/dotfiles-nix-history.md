# dotfiles-nix Commit History Index

> **Repository:** `megalithic/dotfiles-nix`
> **Archive Date:** 2025-12-15
> **Total Commits:** 376
> **Date Range:** 2025-09-03 to 2025-12-15
> **Latest Commit:** `abeb979` (fix(hammerspoon): fix notification subtitle parameter and add mprocs)

---

## AI Agent Reference Instructions

This document serves as a **searchable index** of the commit history from the original `dotfiles-nix` repository. It contains the foundational work for:

- **Hammerspoon** notification system, watchers, and automation
- **nix-darwin** and **home-manager** configuration patterns
- **Claude/AI integration** (MCP servers, skills, statusline)
- **ntfy** notification routing system
- **mkApp/mkCask** unified macOS app builders
- **jujutsu (jj)** workflow integration

### How to Use This Index

When you need more context about a specific commit:

#### 1. Check Local Repository First (Preferred)

```bash
# The archived repo should be at:
~/code/dotfiles-nix

# View full commit details:
cd ~/code/dotfiles-nix && git show <commit-sha>

# View files changed:
cd ~/code/dotfiles-nix && git show --stat <commit-sha>

# View full diff:
cd ~/code/dotfiles-nix && git show -p <commit-sha>

# Search commit messages:
cd ~/code/dotfiles-nix && git log --grep="<search-term>" --oneline

# Search code at a specific commit:
cd ~/code/dotfiles-nix && git show <commit-sha>:<file-path>
```

#### 2. Fallback: GitHub API (if local repo unavailable)

If `~/code/dotfiles-nix` doesn't exist, use the GitHub API:

```bash
# Get commit details via gh CLI:
gh api repos/megalithic/dotfiles-nix/commits/<full-sha>

# Get commit with diff:
gh api repos/megalithic/dotfiles-nix/commits/<full-sha> --jq '.files[] | "\(.filename): +\(.additions) -\(.deletions)"'

# Search commits:
gh api "repos/megalithic/dotfiles-nix/commits?per_page=100" --jq '.[] | "\(.sha[:7]) \(.commit.message | split("\n")[0])"'

# Get file contents at a commit:
gh api repos/megalithic/dotfiles-nix/contents/<file-path>?ref=<commit-sha> --jq '.content' | base64 -d
```

**Note:** The repository is archived and private. API access requires appropriate authentication.

### Key Knowledge Areas

| Topic | Search Terms | Notable Commits |
|-------|--------------|-----------------|
| Notification System | `notif`, `ntfy`, `pushover`, `canvas` | `134c8a0`, `6e849b0`, `cc57cd6` |
| macOS Sequoia Fixes | `sequoia`, `AX`, `accessibility` | `134c8a0` |
| Claude/AI Integration | `claude`, `mcp`, `skill`, `statusline` | `7fc0886`, `d2f6076`, `282a494` |
| nix-darwin Architecture | `darwin`, `module`, `flake` | `15c1f81`, `7e3f0f8`, `c083273` |
| mkApp/mkCask Builders | `mkApp`, `mkCask`, `brew`, `cask` | `9efa775`, `15c1f81`, `bacf6ef` |
| Hammerspoon | `hammerspoon`, `hs`, `watcher` | `134c8a0`, `98c3a4b`, `0fb830e` |
| jujutsu Workflow | `jj`, `jujutsu`, `bookmark` | `2a7011b`, `7fc0886` |

---

## Commit History

| Date | SHA | Subject |
|------|-----|---------|
| 2025-09-03 | `599e01a` | Initial commit of mega_mvim and EARLY nix setup |
| 2025-09-08 | `2106a12` | wip: more splitting out and cleaning up of home/darwin |
| 2025-09-08 | `dfadd2d` | wip: adds lots of good ref links to home.nix; passes currentsystem*name to darwin.nix |
| 2025-09-08 | `1503c1a` | ref: add ethan holz link as a ref |
| 2025-09-08 | `f6b7016` | ref: more links for nerd-font use, sop use, jj/nvim things |
| 2025-09-08 | `79060a0` | attempting to run the thing again |
| 2025-09-08 | `4c91aca` | shell init script spelling fix |
| 2025-09-09 | `93561ce` | debug init script; agenix secrets file setup; more darwin config |
| 2025-09-09 | `0abf511` | adding notes for future zsh prompt updates, buuut, fish instead? |
| 2025-09-09 | `f70b43b` | fix(nix)!: huge changes that should have this working on first shot |
| 2025-09-09 | `214d6b6` | moves ref links to references.md |
| 2025-09-10 | `85f5899` | feat(nvim): update configs a big; adds beta mini.nvim config |
| 2025-09-10 | `230b7fe` | remove zsh plugins; don't want those versioned |
| 2025-09-11 | `81ae9b4` | starship config with some tmux nix setup |
| 2025-09-11 | `1e79ddb` | feat(nvim): the great autocmds migration™ |
| 2025-09-12 | `be73bb2` | just do, pls |
| 2025-09-12 | `46526b5` | really get things working for init script |
| 2025-09-12 | `8b1faf1` | more flake debugging for mkInit |
| 2025-09-15 | `6df21f5` | feat(nvim): mini.pick and smart picker; jj fixes? |
| 2025-09-15 | `c21ea2c` | wip(nix): get build steps working for first time nix'ifying |
| 2025-09-15 | `d7ea368` | feat(jj): mimic some aliases from git-land |
| 2025-09-15 | `ebb0e6a` | wip(nix) |
| 2025-09-15 | `8cb5005` | wip(nix) |
| 2025-09-15 | `fe1aabb` | wip(nix) |
| 2025-09-15 | `5d51b17` | wip(nix) |
| 2025-09-15 | `8412390` | wip(nix) |
| 2025-09-15 | `f6a1f80` | wip(nix) |
| 2025-09-15 | `bddebf0` | wip(nix) |
| 2025-09-15 | `1028fdb` | wip(nix) |
| 2025-09-15 | `4059834` | wip(nix) |
| 2025-09-15 | `cc6dc4f` | wip(nix) |
| 2025-09-15 | `cc4cf63` | wip(nix) |
| 2025-09-15 | `ce7f1ca` | wip(nix) |
| 2025-09-15 | `7ffaaff` | wip(nix) |
| 2025-09-16 | `a12e913` | wip(nix) |
| 2025-09-16 | `361475b` | wip(nix) |
| 2025-09-16 | `afa9a22` | wip(nix) |
| 2025-09-16 | `841a872` | wip(nix) |
| 2025-09-17 | `37d8058` | wip(nix) |
| 2025-09-17 | `10acf8b` | wip(nix) |
| 2025-09-17 | `b66234d` | wip(nix): initial install scripts |
| 2025-09-17 | `7b8a86d` | wip(nix): fixes install script |
| 2025-09-17 | `e751732` | wip(nix): conditionally run homebrew installer |
| 2025-09-17 | `3b300dd` | wip(nix): fix that condition |
| 2025-09-17 | `d8f313b` | wip(nix): fix that condition again |
| 2025-09-17 | `b315fb4` | wip(nix): fix that condition again |
| 2025-09-17 | `4bc3903` | wip(nix): fix that condition again |
| 2025-09-17 | `054a2bb` | wip(nix): fix that condition again |
| 2025-09-17 | `30ff4b2` | wip(nix): fix that condition again |
| 2025-09-17 | `8b899cf` | wip(nix): fix that condition again |
| 2025-09-17 | `3cd7ea1` | wip(nix): sudo nix things |
| 2025-09-17 | `f34f452` | wip(nix): sudo nix things |
| 2025-09-17 | `8d05d9c` | wip(nix): sudo nix things |
| 2025-09-17 | `fdb14de` | wip(nix): sudo nix things |
| 2025-09-17 | `f84a274` | wip(nix): sudo nix things |
| 2025-09-17 | `3f17eac` | wip(nix): sudo nix things |
| 2025-09-17 | `30034aa` | wip(nix): sudo nix things |
| 2025-09-17 | `d393fe0` | wip(nix): sudo nix things |
| 2025-09-17 | `1ba49ca` | wip(nix): fix that condition again |
| 2025-09-17 | `10b837c` | wip(nix): fix that condition again |
| 2025-09-17 | `459dc3d` | wip(nix): remove mksystem and use primary megabookpro |
| 2025-09-17 | `83df1eb` | wip(nix): remove mksystem and use primary megabookpro |
| 2025-09-17 | `ee9052c` | wip(nix): remove mksystem and use primary megabookpro |
| 2025-09-17 | `192294b` | wip(nix): tweak init script |
| 2025-09-17 | `06d915f` | docs: note about --refresh |
| 2025-09-17 | `e0315d4` | fix(nix): adjust relative paths to modules |
| 2025-09-17 | `c2e49a5` | fix(nix): unclosed function scope |
| 2025-09-17 | `6e44fcb` | fix(nix): kanata service config file turned off |
| 2025-09-17 | `9cd96a0` | fix(nix): kanata service config file turned off |
| 2025-09-17 | `272c26b` | fix(darwin): correctly nest keyboard settings |
| 2025-09-17 | `b86ba7a` | wip(nix) |
| 2025-09-17 | `cb20bea` | wip(nix) |
| 2025-09-17 | `a6547e1` | wip(nix) |
| 2025-09-17 | `e917350` | wip(nix) |
| 2025-09-17 | `39b8457` | wip(nix) |
| 2025-09-17 | `5c98ddf` | wip(nix) |
| 2025-09-17 | `64d60e3` | wip(nix) |
| 2025-09-17 | `ce9f02d` | wip(nix) |
| 2025-09-17 | `8374a45` | wip(nix) |
| 2025-09-17 | `075b6eb` | wip(nix) |
| 2025-09-17 | `d11bbc7` | wip(nix) |
| 2025-09-17 | `934f968` | wip(nix) |
| 2025-09-17 | `e07b1bf` | wip(nix) |
| 2025-09-17 | `8071fe5` | wip(nix) |
| 2025-09-17 | `f72058b` | wip(nix) |
| 2025-09-17 | `c45c7af` | wip(nix) |
| 2025-09-17 | `aa8cb71` | wip(nix) |
| 2025-09-17 | `d0a8673` | wip(nix) |
| 2025-09-17 | `2aa3ffb` | wip(nix) |
| 2025-09-17 | `c916f15` | wip(nix) |
| 2025-09-17 | `3cdb581` | wip(nix) |
| 2025-09-18 | `cc56b82` | wip(nix): total refactor to a different strategy of declarative layout. |
| 2025-09-19 | `d41289d` | wip(nix): continuing the refactor. |
| 2025-09-19 | `5ac5c70` | wip(nix): continuing the refactor. |
| 2025-09-19 | `4f7f4b3` | wip(nix): continuing the refactor. |
| 2025-09-19 | `d0fe03c` | wip(nix): continuing the refactor. |
| 2025-09-19 | `a09768e` | wip(nix): continuing the refactor. |
| 2025-09-19 | `0bdf72a` | wip(nix): continuing the refactor. |
| 2025-09-19 | `5596fbe` | wip(nix): continuing the refactor. |
| 2025-09-19 | `af6a1b9` | wip(nix): continuing the refactor. |
| 2025-09-19 | `db23ebe` | wip(nix): continuing the refactor. |
| 2025-09-19 | `efac265` | wip(nix): continuing the refactor. |
| 2025-09-19 | `b32bfc8` | wip(nix): continuing the refactor. |
| 2025-09-19 | `0e6c986` | wip(nix): continuing the refactor. |
| 2025-09-19 | `0824753` | wip(nix): continuing the refactor. |
| 2025-09-19 | `9e55133` | wip(nix): continuing the refactor. |
| 2025-09-19 | `1dee625` | wip(nix): continuing the refactor. |
| 2025-09-19 | `beedc09` | wip(nix): continuing the refactor. |
| 2025-09-19 | `cce9423` | wip(nix): continuing the refactor. |
| 2025-09-19 | `a6dd1d9` | wip(nix): continuing the refactor. |
| 2025-09-19 | `8d52b1f` | wip(nix): continuing the refactor. |
| 2025-09-19 | `fd1b0dd` | wip(nix): continuing the refactor. |
| 2025-09-19 | `a1b387d` | wip(nix): continuing the refactor. |
| 2025-09-19 | `b5e74f5` | wip(nix): continuing the refactor. |
| 2025-09-19 | `ddab3c2` | wip(nix): continuing the refactor. |
| 2025-09-19 | `c07d80d` | wip(nix): continuing the refactor. |
| 2025-09-20 | `a602012` | wip(nix): continuing the refactor. |
| 2025-09-20 | `57ca10a` | wip(nix): continuing the refactor. |
| 2025-09-20 | `c9fb4af` | wip(nix): continuing the refactor. |
| 2025-09-20 | `f221a24` | wip(nix): continuing the refactor. |
| 2025-09-20 | `2e834c4` | wip(nix): continuing the refactor. |
| 2025-09-20 | `0071c6c` | wip(nix): continuing the refactor. |
| 2025-09-20 | `8e67299` | wip(nix): continuing the refactor. |
| 2025-09-20 | `8e36c95` | wip(nix): continuing the refactor. |
| 2025-09-20 | `84d769c` | wip(nix): continuing the refactor. |
| 2025-09-20 | `430b708` | wip(nix): continuing the refactor. |
| 2025-09-20 | `c5fa159` | wip(nix): continuing the refactor. |
| 2025-09-20 | `afe5ecf` | wip(nix): continuing the refactor. |
| 2025-09-20 | `b05c5f9` | wip(nix): continuing the refactor. |
| 2025-09-20 | `01a5a1b` | wip(nix): continuing the refactor. |
| 2025-09-20 | `eaa6c13` | wip(nix): continuing the refactor. |
| 2025-09-20 | `0f5bfc0` | wip(nix): add git configs; rename existing taps. |
| 2025-09-22 | `4018c28` | wip(nix): _hopefully_ get passed the existing copy of homebrew issue. |
| 2025-09-22 | `39e2de3` | wip(nix): homebrew package corrections |
| 2025-09-22 | `74d3c41` | wip(nix): homebrew package corrections |
| 2025-09-22 | `2ccdc11` | wip(nix): homebrew package corrections |
| 2025-09-22 | `88901cd` | wip(nix): homebrew package corrections |
| 2025-09-22 | `be3289e` | wip(nix): homebrew package corrections |
| 2025-09-22 | `6e6339a` | wip(nix): homebrew package corrections |
| 2025-09-22 | `eb0db68` | wip(nix): homebrew package corrections |
| 2025-09-22 | `008503b` | wip(nix): homebrew package corrections |
| 2025-09-22 | `9c2a37f` | wip(nix): homebrew package corrections |
| 2025-09-22 | `7ae9001` | wip(nix): homebrew package corrections |
| 2025-09-22 | `a0690b1` | wip(nix): homebrew package corrections |
| 2025-09-22 | `ff22615` | wip(nix): homebrew package corrections |
| 2025-09-22 | `69f873c` | wip(nix): homebrew package corrections |
| 2025-09-22 | `87758e4` | wip(nix): homebrew package corrections |
| 2025-09-22 | `f8ab448` | wip(nix): homebrew package corrections |
| 2025-09-22 | `05b34dc` | wip(nix): homebrew package corrections |
| 2025-09-22 | `82fe727` | wip(nix): homebrew package corrections |
| 2025-09-22 | `e4b388e` | wip(nix): homebrew package corrections |
| 2025-09-22 | `09be2d1` | wip(nix): homebrew package corrections |
| 2025-09-22 | `f16c0b3` | wip(nix): homebrew package corrections |
| 2025-09-22 | `1141cd8` | wip(nix): homebrew package corrections |
| 2025-09-22 | `904b168` | wip(nix): reuse old hammerspoon config; try to get ghostty working again |
| 2025-09-22 | `e0af25c` | wip(nix): reuse old hammerspoon config; try to get ghostty working again |
| 2025-09-22 | `4f9aad1` | wip(nix): hopefully uninstall ghostty brew to reinstall ghostty@tip |
| 2025-09-22 | `b876bb9` | wip(nix): hopefully uninstall ghostty brew to reinstall ghostty@tip; part 2 |
| 2025-09-22 | `7a0d010` | wip(nix): hopefully uninstall ghostty brew to reinstall ghostty@tip; part 2 |
| 2025-09-23 | `3472fc2` | wip(nix): ignores |
| 2025-09-23 | `55febc8` | wip(nix): makes out of store symlink for nvim/hs/ghostty |
| 2025-09-23 | `bbabf4e` | nix: updates to how we link nvim/hs/ghostty and also updates to jujutsu |
| 2025-09-23 | `d5366a4` | nix: add linux-builder, more brewbrew/darwin tweaks |
| 2025-09-23 | `727f2db` | update readme and justfile with uninstaller |
| 2025-09-23 | `d6c3d11` | nix: tweaks to justfile and nix init scripts |
| 2025-09-23 | `3b3bede` | nix: adds delta to system packages |
| 2025-09-23 | `e88a987` | docs: update readme with more up to date info about dotfiles-nix |
| 2025-09-23 | `a4da948` | nix: init script updated again |
| 2025-09-23 | `8ada169` | nix: fix init script.. wrong params |
| 2025-09-23 | `f147db6` | nix: fix init script.. still, wrong interpolation |
| 2025-09-23 | `6fe87e4` | nix: yep init script fixes; bare repo shenanigans |
| 2025-09-23 | `105943e` | nix: init script bare repo convert |
| 2025-09-23 | `638e23b` | nix: init script; doesn't like bare repo initially |
| 2025-09-23 | `7bd06dc` | nix(hm): fix programs.git |
| 2025-09-23 | `aaf2868` | nix(hm): fix jujutsu config; still need fix tools |
| 2025-09-23 | `9db3619` | nix(hm): fix vss account info config |
| 2025-09-23 | `441b1ed` | nix(hm): disable vcs accounts config for now |
| 2025-09-23 | `204368f` | nix(hm): remove backupFileExtension duplication |
| 2025-09-23 | `dfff3f2` | nix(hm): mkoutofstoresymlink changes for nvim |
| 2025-09-23 | `dfd1a01` | nix(hs): just want correct nvim linking |
| 2025-09-23 | `c887938` | nix(hs): nvim .vimrc things |
| 2025-09-23 | `2120e08` | nix: disable nix |
| 2025-09-23 | `482e610` | nix: more homebrew cask shenanigans |
| 2025-09-23 | `6859971` | wip(nix): fixes towards working nvim |
| 2025-09-23 | `51d1a0d` | wip(nix): continued |
| 2025-09-23 | `b01a45f` | wip(nix): continued |
| 2025-09-23 | `dd87722` | wip(nix): continued |
| 2025-09-23 | `14d6adb` | wip(nix): continued |
| 2025-09-23 | `1d13e2f` | wip(nix): continued |
| 2025-09-23 | `da67196` | wip(nix): continued |
| 2025-09-23 | `b866808` | wip(nix): continued |
| 2025-09-23 | `58f62bc` | wip(nix): continued |
| 2025-09-23 | `fcb2614` | wip(nix): continued |
| 2025-09-23 | `2d832ce` | wip(nix): fixing homebrew; hm configs |
| 2025-09-24 | `2274160` | fix(nix): remove homebrew and reinstall |
| 2025-09-24 | `90eaa31` | fix(nix): ghostty fails to start due to wanting homebrew zsh |
| 2025-09-24 | `27e4f05` | chore(nix): init script updates and prettifying |
| 2025-09-24 | `2ab186c` | feat(nix): adds ability to alias a brew app as a pkg; aka, for ghostty |
| 2025-09-24 | `9025dc9` | feat(nix): tmux mostly working; aerc and account changes |
| 2025-09-24 | `5a7275e` | fix(nix): mbsync config |
| 2025-09-24 | `b02e157` | fix(accounts): remove search attrset |
| 2025-09-24 | `3b89220` | fix(tmux) shell to fish, i hope |
| 2025-09-24 | `bd8ff7a` | fix(tmux) shell to fish, i hope |
| 2025-09-24 | `7a09a85` | nix: get bin dir linked; fix ftm; add espanso service |
| 2025-09-24 | `961b926` | just: updates |
| 2025-09-24 | `0d084c0` | fix espanso programs |
| 2025-09-24 | `ada20b7` | fix espanso |
| 2025-09-24 | `a0dc0c2` | fix |
| 2025-09-24 | `7c209b9` | fix |
| 2025-09-24 | `a20f90b` | fix |
| 2025-09-24 | `5b6ba71` | nix: add git-lfs package |
| 2025-09-25 | `9fcded9` | nix: several updates and additions, bringing back nix-homebrew again. |
| 2025-09-25 | `020e93e` | nix: fix homebrew config |
| 2025-09-25 | `9e28367` | chore: removed isntalled mise; trying new |
| 2025-09-25 | `c6e074b` | fix: adjust trash alias path |
| 2025-09-25 | `24fabe0` | nix: adds more dev packages to use for contract work |
| 2025-09-25 | `bc02d25` | oops |
| 2025-09-25 | `131940a` | oops again |
| 2025-09-25 | `23d3cb2` | fixes |
| 2025-09-25 | `cf384a4` | wip: nvim |
| 2025-09-25 | `f863b99` | fix(ssh): don't usekeychain |
| 2025-09-26 | `c0b0e50` | nvim: switching to mini.pick/fff |
| 2025-09-26 | `a70a16d` | wip(nix): tmux/ssh/nvim/fzf/fish |
| 2025-09-26 | `c1eac70` | wip(:nix): trying to get git to git |
| 2025-09-26 | `0eafca0` | git: always use ssh |
| 2025-09-26 | `d32c29f` | tmux |
| 2025-09-28 | `22ad0f8` | nvim: mini.pick mappings not working |
| 2025-09-28 | `b7f9d04` | wip(tmux): fix rendering bugs with the term used |
| 2025-09-29 | `466e5d2` | tmux: fixes to loading (and maybe hammerspoon?) |
| 2025-09-29 | `2e15402` | tmux: use zoxide for the session builder |
| 2025-09-30 | `1d535e6` | nvim: mini pick madness |
| 2025-09-30 | `8b02f8d` | tmux: adds launchdeck layout |
| 2025-09-30 | `cff5873` | readme: add source nix step |
| 2025-09-30 | `1aaf07e` | wip(tmux) |
| 2025-09-30 | `b23164d` | wip(tmux) |
| 2025-09-30 | `0573e3d` | tmux: fix symlinking |
| 2025-09-30 | `7d3bafa` | chore: remove old/nix managed hammerspoon |
| 2025-09-30 | `74a6909` | chore: script updates |
| 2025-09-30 | `68ffd91` | update: blanket update of lots of things |
| 2025-09-30 | `1604c71` | darwin system updates |
| 2025-09-30 | `ca02a82` | more |
| 2025-10-01 | `029912f` | espanso and qutebrowser |
| 2025-10-01 | `902f1e2` | many things |
| 2025-10-02 | `fc9e589` | updates |
| 2025-10-02 | `7f86148` | chore(nix): updates flake.lock |
| 2025-10-02 | `17d95f5` | wip: kanata/karabiner-driver stuff |
| 2025-10-03 | `d602860` | wip |
| 2025-10-03 | `91eb3e0` | wip |
| 2025-10-06 | `c348e8e` | keyboard supports; kanata and karabiner |
| 2025-10-06 | `64e4913` | back to karabiner, still need to figure out kanata |
| 2025-10-06 | `3b153a3` | wip(nvim): trying to get vsplit to work with mini.pick and the fancy full buffer preview |
| 2025-10-06 | `c8633db` | wip(helium): working on getting helium installed and configured via nix |
| 2025-10-06 | `31f4a1b` | yep |
| 2025-10-06 | `7b7d03e` | helium |
| 2025-10-06 | `f2cc8e0` | quick update to rename aerc |
| 2025-10-07 | `1c891fa` | mail |
| 2025-10-07 | `079bcd0` | mail |
| 2025-10-07 | `38a8ea2` | oops |
| 2025-10-07 | `8313bbc` | oops |
| 2025-10-07 | `62a8be2` | mail.. part duex |
| 2025-10-07 | `cade1fb` | mail.. part tres |
| 2025-10-08 | `c6a2b13` | feat: lots of bueno updates for clean up; |
| 2025-10-23 | `2c52698` | ngs |
| 2025-10-27 | `3c19f23` | updates(nvim,nix,tmux,ai,fish,fzf) |
| 2025-10-27 | `4e8c4ed` | nvim/snacks updates |
| 2025-10-29 | `8e6143b` | nvim/snacks picker updates |
| 2025-10-29 | `f6a79d1` | nvim/markdown/blink |
| 2025-10-30 | `7a51875` | feat(hs): audio watchers and setters |
| 2025-10-30 | `7a72aa2` | feat(hs): new docking mode |
| 2025-10-31 | `2f3af9c` | feat(hs): network-status, docking, audio, camera |
| 2025-11-03 | `95b68be` | feat(hs): reintroduce app contexts, simplified |
| 2025-11-04 | `d8a3ee1` | feat(hs): fixes to contexts/app watcher |
| 2025-11-05 | `afcd743` | feat(hs): teams context |
| 2025-11-06 | `f37a479` | feat(hs): notification routing system with sqlite tracking |
| 2025-11-06 | `3671c9a` | feat(hs): fast focus mode detection with JXA |
| 2025-11-06 | `721e996` | feat(hs): add app icons to notifications with click-to-focus |
| 2025-11-06 | `7abe440` | feat(hs): priority-based notification routing with auto-dismiss |
| 2025-11-07 | `1356ef5` | feat(hs): hal 9000 icon for AI notifications + camera app detection |
| 2025-11-09 | `d62952a` | wip(hs/ai): continued efforts of hs notifications and ai things |
| 2025-11-10 | `ab3fe5e` | refactor(hs): notification system |
| 2025-11-10 | `a9ef5d0` | fix(notifier): attention detection logic adjusted |
| 2025-11-11 | `7d7c74f` | feat(nix): adds nix-casks and splits packages files up a bit |
| 2025-11-11 | `f9c4b9e` | docs(workflow): establish jujutsu version control workflow for AI-assisted development |
| 2025-11-11 | `c783ac6` | debug(notifications): root cause identified - AXLayoutChanged broken on macOS Sequoia |
| 2025-11-11 | `9adc4cb` | fix(notifications): add debug logging to diagnose AXLayoutChanged callback issue |
| 2025-11-12 | `a042bed` | fix(notifications): fix N.process() function call + create clean public API |
| 2025-11-12 | `4abba1a` | feat(notifications): add date and time to menubar tooltip |
| 2025-11-12 | `9bbf29c` | refactor(notifications): remove debug logging from processor and watcher |
| 2025-11-12 | `2bc51be` | feat(vpn): add GUI automation and notification support |
| 2025-11-12 | `f78f4ff` | fix(hammerspoon): fix watchers, add pushover, optimize reload |
| 2025-11-12 | `e026ede` | feat(ci): add automated flake updates via GitHub Actions |
| 2025-11-12 | `6fd036b` | chore(deps): bump stefanzweifel/git-auto-commit-action from 5 to 7 |
| 2025-11-12 | `dea9742` | feat(ci): add nix config validation workflow + improve die script |
| 2025-11-12 | `26e0a99` | feat(secrets): add agenix + fix(hammerspoon): errors and camera debouncing |
| 2025-11-12 | `3dd340d` | nix: updates to get agenix working |
| 2025-11-13 | `c85b4a9` | wip: agenix |
| 2025-11-13 | `a94bd18` | nix(secrets) env-vars |
| 2025-11-16 | `fcb1eeb` | chore(nix): update flake.lock [skip ci] |
| 2025-11-17 | `c736d59` | updates: nix, nix-casks, hs, seal and other things |
| 2025-11-18 | `05021ab` | feat(nix): add mkCask derivation for Homebrew casks |
| 2025-11-18 | `cbb772c` | Merge pull request #1 from megalithic/dependabot/github_actions/stefanzweifel/git-auto-commit-action-7 |
| 2025-11-18 | `3b4f7a0` | Merge pull request #2 from megalithic/feat/mkcask |
| 2025-11-18 | `d58e975` | ¯\_(ツ)_/¯ |
| 2025-11-18 | `bbabdba` | .. |
| 2025-11-18 | `60051ae` | cleanup |
| 2025-11-18 | `0a86dcb` | wip |
| 2025-11-18 | `13fb871` | . |
| 2025-11-19 | `0359bda` | wip: path changes/nix fixes/mailmate config/more |
| 2025-11-20 | `505edeb` | wip: hammerspoon, nvim, helium prep, and config updates |
| 2025-11-20 | `9cd3bd8` | feat(helium): enable developer mode and fix widevine activation |
| 2025-11-20 | `612aa47` | feat(karabiner): add Karabiner-Elements without homebrew |
| 2025-11-20 | `c1ca754` | chore: organize auto-generated docs in _docs directory |
| 2025-11-20 | `cc26366` | merge: bring in notification routing system |
| 2025-11-20 | `e868eeb` | merge: bring in nvim, tmux, ai, and config updates |
| 2025-11-20 | `241a088` | fix(tmux/layouts): updates |
| 2025-11-20 | `c349775` | feat(nix): adds expert ls overlay |
| 2025-11-20 | `1daef63` | feat(ai): adds some initial claude system prompt thingies |
| 2025-11-23 | `0919ab1` | chore(nix): update flake.lock [skip ci] |
| 2025-11-26 | `df9131a` | wip |
| 2025-11-26 | `bacf6ef` | feat(nix): implement mkCask copyToApplications for strict apps and migrate home-manager config |
| 2025-11-26 | `f8e2ce0` | fix(hammerspoon): restore source files and fix symlink direction |
| 2025-11-26 | `1293a6c` | fix(clipper): source agenix env vars and nix PATH in capper |
| 2025-11-28 | `eaf187f` | fix(hs/capper): better notification output for proper clicking of url |
| 2025-11-28 | `30042af` | fix(hs/capper): better notification output for proper clicking of url |
| 2025-11-28 | `0663077` | feat(nix-darwin): add custom karabiner-elements module for v15+ |
| 2025-11-28 | `9977f71` | fix(karabiner): clear xattrs to prevent 'damaged app' errors |
| 2025-11-28 | `4967514` | fix(karabiner): clear xattrs on all copied files to prevent 'damaged app' errors |
| 2025-11-30 | `d2aac20` | chore(nix): update flake.lock [skip ci] |
| 2025-12-01 | `15c1f81` | refactor: major dotfiles reorganization and mkApp unification |
| 2025-12-01 | `771bfcd` | docs(CLAUDE.md): use darwin-rebuild for cleaner verifiable output |
| 2025-12-02 | `0b8fb28` | fix: hammerspoon now properly refed |
| 2025-12-02 | `2244356` | docs: fix readme |
| 2025-12-04 | `0025af6` | wip: continuing the move back to homebrew and expert lsp setup |
| 2025-12-07 | `527ee01` | chore(nix): update flake.lock [skip ci] |
| 2025-12-08 | `0fb830e` | refactor: hammerspoon cleanup and camera watcher improvements |
| 2025-12-08 | `34b6e71` | feat(notifications): add smart truncation with remaining char count |
| 2025-12-09 | `9efa775` | feat(mkApp): add unified macOS app builder and chrome-devtools-mcp |
| 2025-12-09 | `526bc1a` | feat(fantastical): update to version 4.1.5 |
| 2025-12-09 | `d2f6076` | feat(mcp): use mcp-servers-nix lib and declarative bin symlinks |
| 2025-12-09 | `98c3a4b` | refactor(hammerspoon): camera watcher and context improvements |
| 2025-12-09 | `7432416` | feat(bin): add utility scripts for browser debugging and wifi |
| 2025-12-09 | `2526204` | chore: misc updates and config changes |
| 2025-12-09 | `2a7011b` | docs(CLAUDE.md): strengthen jj workflow accountability |
| 2025-12-09 | `329e2ba` | fix(mcp): configure memory server with writable storage path |
| 2025-12-09 | `50ff513` | refactor(nix): reorganize packages/overlays to idiomatic structure |
| 2025-12-09 | `57f9781` | feat(git): add pre-commit hook to block nix store symlinks |
| 2025-12-10 | `7e3f0f8` | refactor(nix): simplify structure for single-user Darwin setup |
| 2025-12-10 | `396d259` | refactor(browsers): reorganize chromium/ to browsers/ with better naming |
| 2025-12-10 | `5d4f7e7` | refactor(nix): consolidate overlays and pkgs structure |
| 2025-12-10 | `0036614` | feat(browsers): sync extensions and remote debugging for Helium and Brave |
| 2025-12-10 | `b1b4b4e` | refactor: replace find/grep with fd/rg in activation scripts |
| 2025-12-10 | `8631212` | refactor(home): centralize AI tools config in programs/ai.nix |
| 2025-12-10 | `7fc0886` | feat(claude): declarative programs.claude-code module + enhanced statusline |
| 2025-12-10 | `2dd5583` | feat(statusline): add animated spinner for loading token data |
| 2025-12-10 | `c083273` | refactor(modules): flatten darwin subfolder |
| 2025-12-11 | `134c8a0` | fix(hammerspoon): notification watcher for macOS Sequoia AX changes |
| 2025-12-11 | `ded5e3d` | chore(ai): disable unused MCP servers |
| 2025-12-11 | `26915a8` | fix(notifier): add macOS NC logging for canvas notifications |
| 2025-12-11 | `6e849b0` | feat(notifier): add unified N.send() API with ntfy shell wrapper |
| 2025-12-11 | `dce8c70` | docs(claude): replace name with generic 'user' reference |
| 2025-12-11 | `e2c5067` | refactor(nix): add lib.mega helpers and reorganize home config |
| 2025-12-11 | `b74d094` | feat(nix): add nix skill and consolidate lib under lib.mega namespace |
| 2025-12-11 | `282a494` | refactor(ai): externalize skills to docs/skills/ with builtins.readFile |
| 2025-12-12 | `f4d571c` | docs(nix): add home-manager options search and telegram-desktop |
| 2025-12-12 | `cc57cd6` | feat(ntfy): add pane-level tmux detection and source auto-detection |
| 2025-12-12 | `8b3ac4c` | refactor(notifications): replace allowedFocusModes with overrideFocusModes |
| 2025-12-12 | `394b817` | fix(notifications): handle nil message body in canvas notifications |
| 2025-12-12 | `34416d9` | docs: update ntfy documentation and rename skill |
| 2025-12-12 | `29d0678` | feat(nix): add process-compose config and disable brew quarantine |
| 2025-12-12 | `bfa3312` | chore(hammerspoon): minor cleanups and skill rename |
| 2025-12-12 | `80fbd7f` | fix(notifications): strip nix store paths and remove program prefix |
| 2025-12-12 | `be8e966` | chore: migrate to ntfy and remove legacy notifier script |
| 2025-12-12 | `9c69608` | feat(notifications): add Telegram rule and fix lua fish completion collision |
| 2025-12-14 | `9d4fbc4` | chore(nix): update flake.lock [skip ci] |
| 2025-12-15 | `e15b19a` | refactor(hammerspoon): flatten notifier config structure |
| 2025-12-15 | `abeb979` | fix(hammerspoon): fix notification subtitle parameter and add mprocs |
