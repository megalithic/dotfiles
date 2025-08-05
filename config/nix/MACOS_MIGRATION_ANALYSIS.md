# macOS Settings Migration Analysis

## Overview

This document analyzes the compatibility between your existing `./macos` script and nix-darwin's `system.defaults` configuration. The analysis covers macOS Sonoma and Ventura compatibility.

## Compatibility Summary

- **✅ Fully Translatable**: ~60% of settings
- **⚠️ Partially Translatable**: ~20% of settings (via CustomPreferences)
- **❌ Not Translatable**: ~20% of settings (require manual scripts)

---

## ✅ **FULLY TRANSLATABLE to nix-darwin**

### NSGlobalDomain Settings (Lines 71-218)

These settings map directly to `system.defaults.NSGlobalDomain`:

#### Sound Settings
- `com.apple.sound.beep.flash` → `com.apple.sound.beep.flash`
- `com.apple.sound.uiaudio.enabled` → `com.apple.sound.uiaudio.enabled`

#### Keyboard Settings
- `AppleKeyboardUIMode` → `AppleKeyboardUIMode`
- `KeyRepeat` → `KeyRepeat`
- `InitialKeyRepeat` → `InitialKeyRepeat`
- `ApplePressAndHoldEnabled` → `ApplePressAndHoldEnabled`

#### Text Input Settings
- `NSAutomaticCapitalizationEnabled` → `NSAutomaticCapitalizationEnabled`
- `NSAutomaticDashSubstitutionEnabled` → `NSAutomaticDashSubstitutionEnabled`
- `NSAutomaticPeriodSubstitutionEnabled` → `NSAutomaticPeriodSubstitutionEnabled`
- `NSAutomaticQuoteSubstitutionEnabled` → `NSAutomaticQuoteSubstitutionEnabled`
- `NSAutomaticSpellingCorrectionEnabled` → `NSAutomaticSpellingCorrectionEnabled`

#### Dialog Settings
- `NSNavPanelExpandedStateForSaveMode` → `NSNavPanelExpandedStateForSaveMode`
- `PMPrintingExpandedStateForPrint` → `PMPrintingExpandedStateForPrint`
- `NSDocumentSaveNewDocumentsToCloud` → `NSDocumentSaveNewDocumentsToCloud`

#### UI Settings
- `AppleShowScrollBars` → `AppleShowScrollBars`
- `_HIHideMenuBar` → `_HIHideMenuBar`

### Trackpad Settings (Lines 127-150)

Maps to `system.defaults.trackpad`:

- `Clicking` → `Clicking` (tap to click)
- `TrackpadThreeFingerDrag` → `TrackpadThreeFingerDrag`
- `TrackpadCornerSecondaryClick` → `TrackpadCornerSecondaryClick`
- `com.apple.swipescrolldirection` → Natural scrolling setting

### Dock Settings (Lines 155-167)

Maps to `system.defaults.dock`:

- `autohide` → `autohide`
- `autohide-delay` → `autohide-delay`
- `autohide-time-modifier` → `autohide-time-modifier`
- `tilesize` → `tilesize`
- `showhidden` → `showhidden`
- `mru-spaces` → `mru-spaces`

### Finder Settings (Lines 241-293)

Maps to `system.defaults.finder`:

- `AppleShowAllExtensions` → `AppleShowAllExtensions`
- `ShowPathbar` → `ShowPathbar`
- `ShowStatusBar` → `ShowStatusBar`
- `FXPreferredViewStyle` → `FXPreferredViewStyle`
- `FXEnableExtensionChangeWarning` → `FXEnableExtensionChangeWarning`
- `FXDefaultSearchScope` → `FXDefaultSearchScope`
- `_FXShowPosixPathInTitle` → `_FXShowPosixPathInTitle`
- `_FXSortFoldersFirst` → `_FXSortFoldersFirst`

---

## ⚠️ **PARTIALLY TRANSLATABLE** 

These can be configured using `system.defaults.CustomUserPreferences` or `system.defaults.CustomSystemPreferences`:

### Screenshot Settings (Lines 99-108)
```nix
system.defaults.CustomUserPreferences = {
  "com.apple.screencapture" = {
    location = "";
    type = "jpg";
    name = "";
    disable-shadow = true;
  };
};
```

### Safari Settings (Lines 298-346)
```nix
system.defaults.CustomUserPreferences = {
  "com.apple.Safari" = {
    UniversalSearchEnabled = false;
    SuppressSearchSuggestions = true;
    WebKitTabToLinksPreferenceKey = true;
    ShowFullURLInSmartSearchField = true;
    # ... and more
  };
};
```

### Activity Monitor Settings (Lines 379-391)
```nix
system.defaults.CustomUserPreferences = {
  "com.apple.ActivityMonitor" = {
    OpenMainWindow = true;
    IconType = 5;
    ShowCategory = 0;
    SortColumn = "CPUUsage";
    SortDirection = 0;
  };
};
```

### Other App-Specific Settings
- **Hammerspoon** config path (Line 469)
- **Chrome** backswipe disable (Lines 452-463)  
- **Terminal** settings (Lines 351-362)
- **Time Machine** settings (Lines 368-374)
- **Text Edit** settings (Lines 396-401)

---

## ❌ **NOT TRANSLATABLE** 

These require manual shell scripts and cannot be managed by nix-darwin:

### System-Level Commands
- **Power management** (`pmset`, Lines 61-66)
- **NVRAM settings** (`nvram`, Lines 69, 76)
- **Security settings** (`spctl --master-disable`, Line 79)
- **Network/hostname** (`scutil`, Lines 84-89)
- **File system operations** (`chflags nohidden`, Lines 289-292)
- **Bluetooth audio codecs** (Lines 114-115)

### Application Management
- **Dock app removal** (Lines 508-530)
- **App launching/startup configuration** (Lines 573-616)
- **Font installation** (Line 493)
- **Symlink creation** (Line 92)

### User Directory Creation
- **Creating directories** (`mkdir ~/code ~/tmp`, Lines 46-52)

---

## 🔄 **SONOMA/VENTURA COMPATIBILITY**

### Both Versions Support
- ✅ All nix-darwin `system.defaults` options work identically
- ✅ Most `defaults write` commands have the same behavior
- ✅ Basic system configuration is stable

### Potential Issues
- ⚠️ **Ventura**: Some users report more stability issues compared to Sonoma
- ⚠️ **System Integrity Protection**: May interfere with certain low-level settings
- ⚠️ **Architecture differences**: Your script handles Apple Silicon vs Intel (Lines 36-39)

### Version-Specific Notes
- **Sonoma (14.x)**: Generally more stable with nix-darwin
- **Ventura (13.x)**: May require additional troubleshooting for some settings
- **Apple Silicon**: Fully supported, architecture detection works correctly

---

## 📋 **MIGRATION STRATEGY**

### Phase 1: Core Settings Migration (~80% coverage)
1. Move all compatible NSGlobalDomain settings to `system.defaults.NSGlobalDomain`
2. Configure trackpad, dock, and finder settings via `system.defaults`
3. Test basic functionality

### Phase 2: App-Specific Settings (~15% coverage)
1. Use `CustomUserPreferences` for Safari, Activity Monitor, etc.
2. Configure screenshot settings
3. Set up Hammerspoon preferences

### Phase 3: System-Level Scripts (~5% coverage)
1. Create a minimal shell script for power management
2. Handle hostname/network configuration
3. Manage font installation and app launching

### Current Status
Your existing `config/nix/darwin/darwin.nix` already includes many core settings. The next step would be to expand it with additional settings from your macOS script.

---

## 🔧 **IMPLEMENTATION NOTES**

### Settings That Require Logout/Restart
- Dock autohide settings
- Trackpad configurations  
- Keyboard repeat rates
- Menu bar autohide

### Settings Applied Immediately
- Finder preferences
- Screenshot settings
- Most NSGlobalDomain settings

### Custom Preferences Syntax
```nix
system.defaults.CustomUserPreferences = {
  "domain.identifier" = {
    setting-name = value;
    boolean-setting = true;
    string-setting = "value";
    integer-setting = 42;
  };
};
```

---

## 📚 **REFERENCES**

- [nix-darwin Manual](https://nix-darwin.github.io/nix-darwin/manual/index.html)
- [MyNixOS Options Reference](https://mynixos.com/nix-darwin/options/system.defaults)
- [macOS defaults command reference](https://macos-defaults.com/)
- [Original macOS script](../../../macos)