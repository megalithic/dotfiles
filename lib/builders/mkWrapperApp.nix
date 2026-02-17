# mkWrapperApp - Create a macOS .app bundle that launches another app with custom args
#
# Creates a proper .app with Info.plist, launcher script, and icon that:
#   - Launches the original app with command-line arguments
#   - Shows up in Finder/Spotlight as a real app
#   - Can be pinned to Dock
#
# Primary use case: Chromium-based browsers that need --remote-debugging-port
# or other flags that can't be passed via nixpkgs darwin wrapper.
#
# Usage:
#   mkWrapperApp {
#     name = "Brave Browser Nightly";
#     originalApp = "${pkgs.brave-browser-nightly}/Applications/Brave Browser Nightly.app";
#     appName = "Brave Browser Nightly";
#     executableName = "Brave Browser Nightly";
#     args = [ "--remote-debugging-port=9222" "--no-first-run" ];
#   }
#
{ pkgs, lib }:

{
  name,           # Display name for the wrapper app
  originalApp,    # Path to the original .app bundle
  appName,        # Original app name (e.g., "Brave Browser Nightly")
  executableName, # Name of executable in Contents/MacOS/
  args,           # Command-line arguments to pass
  iconFile ? "app.icns",  # Icon filename in Resources
  bundleId ? "com.wrapper.app",  # Bundle identifier
}:

pkgs.runCommand "${lib.strings.sanitizeDerivationName name}" {
  nativeBuildInputs = [ pkgs.imagemagick ];
} ''
  mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
  mkdir -p "$out/Applications/${name}.app/Contents/Resources"

  # Create the launcher script
  cat > "$out/Applications/${name}.app/Contents/MacOS/launcher" << 'LAUNCHER'
  #!/bin/bash
  # Wrapper launcher for ${name}
  # Launches the original app with custom command-line arguments

  ORIGINAL_APP="${originalApp}"
  EXECUTABLE="$ORIGINAL_APP/Contents/MacOS/${executableName}"

  if [ ! -x "$EXECUTABLE" ]; then
    osascript -e 'display alert "App Not Found" message "Could not find ${appName} at: '$ORIGINAL_APP'"'
    exit 1
  fi

  exec "$EXECUTABLE" ${lib.escapeShellArgs args} "$@"
  LAUNCHER
  chmod +x "$out/Applications/${name}.app/Contents/MacOS/launcher"

  # Create Info.plist
  cat > "$out/Applications/${name}.app/Contents/Info.plist" << 'PLIST'
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${name}</string>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${bundleId}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
  </dict>
  </plist>
  PLIST

  # Copy icon from original app (with fallback)
  if [ -f "${originalApp}/Contents/Resources/${iconFile}" ]; then
    cp "${originalApp}/Contents/Resources/${iconFile}" "$out/Applications/${name}.app/Contents/Resources/AppIcon.icns"
  else
    echo "Warning: Could not find icon at ${originalApp}/Contents/Resources/${iconFile}"
  fi

  # Create PkgInfo
  echo -n "APPL????" > "$out/Applications/${name}.app/Contents/PkgInfo"
''
