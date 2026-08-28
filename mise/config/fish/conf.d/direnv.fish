# Guard against double-hooking: the nix profile ships a vendor_conf.d
# direnv.fish that also installs the hook while HM's direnv module exists.
command -sq direnv; and not functions -q __direnv_export_eval; and direnv hook fish | source
