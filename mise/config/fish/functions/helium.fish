function helium --description "Launch Helium with declarative flags"
    # Use Home Manager copyApps Helium bundle rather than /Applications/Helium.app,
    # which Sparkle auto-updates and strips of injected Widevine CDM.
    set -l helium "$HOME/Applications/Home Manager Apps/Helium.app/Contents/MacOS/Helium"
    if not test -x "$helium"
        echo "Helium executable not found: $helium" >&2
        return 1
    end

    $helium \
        --no-first-run \
        --no-default-browser-check \
        --hide-crashed-bubble \
        --ignore-gpu-blocklist \
        --disable-breakpad \
        --disable-wake-on-wifi \
        --no-pings \
        --disable-features=OutdatedBuildDetector \
        --remote-debugging-port=9223 \
        $argv \
        >/dev/null 2>&1 &
    disown
end
