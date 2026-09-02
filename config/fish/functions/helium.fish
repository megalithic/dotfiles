function helium --description "Launch Helium with declarative flags"
    # Thin delegate: bin/helium-launch is the single source of truth for the
    # flag set (also used by Hammerspoon's hyper+j cold start). It targets
    # /Applications/Helium.app — the signed megalithic/helium-macos-releases
    # build with Widevine baked in — and detaches before returning.
    "$HOME/bin/helium-launch" $argv
end
