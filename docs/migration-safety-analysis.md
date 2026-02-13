# Migration Safety Analysis

**Date:** 2026-02-13  
**Purpose:** Ensure no configuration loss when migrating apps from Homebrew to Nix

---

## Summary

| App | Config Location | HM Module | Version Match | Safe to Migrate |
|-----|-----------------|-----------|---------------|-----------------|
| Discord | `~/Library/Application Support/discord/` | ✅ `programs.discord` | ✅ 0.0.375 | ✅ Safe |
| Slack | `~/Library/Application Support/Slack/` | ❌ Package only | ✅ 4.47.72 | ⚠️ Safe (no custom config) |
| Zed | `~/Library/Application Support/Zed/` | ✅ `programs.zed-editor` | ⚠️ 0.221.5 vs 0.222.4 | ⚠️ Safe (defaults only) |
| VSCode | `~/Library/Application Support/Code/` | ✅ `programs.vscode` | Check | ✅ Safe |
| Microsoft Teams | `~/Library/Application Support/Microsoft/Teams/` | ❌ Package only | ⚠️ Behind | ⚠️ Test first |
| IINA | System preferences | ❌ Package only | Check | ✅ Safe (no custom config) |
| Inkscape | `~/.config/inkscape/` | ❌ Package only | Check | ✅ Safe |
| Kitty | `~/.config/kitty/` | ✅ `programs.kitty` | Check | ✅ Safe |

---

## Detailed Analysis

### Discord ✅ SAFE

**Current Config:**
```
~/Library/Application Support/discord/settings.json
{
  "offloadAdmControls": true,
  "chromiumSwitches": {}
}
```

**home-manager module:** `programs.discord`
- Manages `settings.json` declaratively
- Default `SKIP_HOST_UPDATE = true` (prevents auto-update nag)
- Config location: `~/Library/Application Support/discord/settings.json`

**Migration:**
```nix
programs.discord = {
  enable = true;
  settings = {
    # Your existing settings preserved
    offloadAdmControls = true;
    chromiumSwitches = {};
    # HM adds SKIP_HOST_UPDATE by default
  };
};
```

**Risk:** None - HM writes to same location, existing settings preserved.

---

### Slack ⚠️ SAFE (No Custom Config)

**Current Config:** 
- `~/Library/Application Support/Slack/` contains cache, cookies, crashes
- No user-editable config files found

**home-manager module:** None (package only)

**Migration:**
```nix
home.packages = [ pkgs.slack ];
```

**Risk:** Low - Slack stores auth/state in Keychain and Application Support. App data persists across reinstalls.

**Post-migration:** Will need to re-login to workspaces.

---

### Zed ⚠️ SAFE (Using Defaults)

**Current Config:**
- `~/Library/Application Support/Zed/` - extensions, db, no settings.json
- No custom settings.json or keymap.json found

**home-manager module:** `programs.zed-editor`
- `userSettings` - settings.json
- `userKeymaps` - keymap.json  
- `extensions` - auto-install extensions

**Migration:**
```nix
programs.zed-editor = {
  enable = true;
  # No settings needed - using defaults
  # Can add extensions later:
  # extensions = [ "nix" "lua" ];
};
```

**Version concern:** Nixpkgs 0.221.5 vs Homebrew 0.222.4 (1 minor version behind)

**Risk:** Low - using defaults, version close enough.

---

### VSCode ✅ SAFE

**Current Config:**
```
~/Library/Application Support/Code/User/settings.json (4 lines)
{
    "github.copilot.nextEditSuggestions.enabled": true,
    "editor.accessibilitySupport": "off",
    "workbench.startupEditor": "none"
}
```

**Extensions (5):**
- ms-vscode-remote.remote-ssh
- ms-vscode-remote.remote-ssh-edit
- ms-vscode.remote-explorer

**home-manager module:** `programs.vscode`
- Full settings management
- Extension management via `extensions` option
- Keybindings support

**Migration:**
```nix
programs.vscode = {
  enable = true;
  userSettings = {
    "github.copilot.nextEditSuggestions.enabled" = true;
    "editor.accessibilitySupport" = "off";
    "workbench.startupEditor" = "none";
  };
  extensions = with pkgs.vscode-extensions; [
    ms-vscode-remote.remote-ssh
    # Others may need marketplace fetch
  ];
};
```

**Risk:** None - small config, HM has full support.

---

### Microsoft Teams ⚠️ TEST FIRST

**Current Config:**
- `~/Library/Application Support/Microsoft/Teams/desktop-config.json`
- Auth stored in Keychain

**home-manager module:** None (package only)

**Version concern:** Nixpkgs behind Homebrew

**Migration:**
```nix
home.packages = [ pkgs.teams ];
```

**Risk:** Medium
- Version lag could cause compatibility issues
- Work app - test in parallel before removing homebrew
- May need to re-authenticate

**Recommendation:** Install nix version alongside homebrew, test for a week before removing homebrew.

---

### IINA ✅ SAFE

**Current Config:**
- No custom config found in Application Support
- Preferences stored in system preferences (plist)

**home-manager module:** None (package only)

**Migration:**
```nix
home.packages = [ pkgs.iina ];
```

**Known Issue:** [#403084](https://github.com/NixOS/nixpkgs/issues/403084) - Finder integration issue (CLOSED - couldn't reproduce)

**Risk:** Low - system preferences persist, may need to reset as default video player.

---

### Inkscape ✅ SAFE

**Current Config:**
- `~/.config/inkscape/` - minimal (cache + config dirs)
- No custom templates or preferences found

**home-manager module:** None (package only)

**Migration:**
```nix
home.packages = [ pkgs.inkscape ];
```

**Risk:** None - minimal config, standard XDG location preserved.

---

### Kitty ✅ SAFE (if migrating)

**Current Config:**
- `~/.config/kitty/kitty.conf` (if exists)
- Currently using Ghostty, may not have config

**home-manager module:** `programs.kitty`
- Full config management
- Theme support
- Shell integration

**Note:** You're using Ghostty now - kitty migration may be unnecessary.

---

## Known Issues to Watch

### Spotlight/Finder Integration

Apps installed via Nix may not appear in Spotlight or work properly with "Open With" in Finder. This is a known macOS limitation with symlinked apps.

**Solutions:**
1. Use mhanberg's alias approach (creates real macOS aliases)
2. Copy apps to /Applications instead of symlink
3. Manually add to Spotlight privacy settings then remove

**Reference issues:**
- [nix-darwin#214](https://github.com/nix-darwin/nix-darwin/issues/214)
- [nix-darwin#1079](https://github.com/nix-darwin/nix-darwin/issues/1079)
- [home-manager#1341](https://github.com/nix-community/home-manager/issues/1341)

### Auto-Updates

Nix-managed apps don't auto-update. This is intentional (reproducibility) but means:
- Security updates require nix update
- May lag behind homebrew versions

Discord's HM module sets `SKIP_HOST_UPDATE = true` by default to prevent update nags.

---

## Migration Order (Recommended)

1. **Phase 1 - Low Risk:**
   - Discord (HM module, version match)
   - Inkscape (no config)
   - IINA (no config)

2. **Phase 2 - Medium Risk:**
   - Slack (re-login required)
   - Zed (version slightly behind)
   - VSCode (HM module available)

3. **Phase 3 - Test First:**
   - Microsoft Teams (work app, version behind)

4. **Phase 4 - Evaluate Need:**
   - Kitty (using Ghostty instead?)

---

## Backup Before Migration

```bash
# Backup app configs before migration
mkdir -p ~/backup/app-configs-$(date +%Y%m%d)
cp -r ~/Library/Application\ Support/discord ~/backup/app-configs-$(date +%Y%m%d)/
cp -r ~/Library/Application\ Support/Slack ~/backup/app-configs-$(date +%Y%m%d)/
cp -r ~/Library/Application\ Support/Code/User ~/backup/app-configs-$(date +%Y%m%d)/
cp -r ~/Library/Application\ Support/Zed ~/backup/app-configs-$(date +%Y%m%d)/
cp -r ~/Library/Application\ Support/Microsoft/Teams ~/backup/app-configs-$(date +%Y%m%d)/
```
