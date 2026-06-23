function helium --description="Launch Helium with declarative flags"
    set -l helium /Applications/Helium.app/Contents/MacOS/Helium
    if not test -x $helium
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
        $argv >/dev/null 2>&1 &
    disown
end
