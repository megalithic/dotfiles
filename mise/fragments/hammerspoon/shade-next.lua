-- Committed static replacement for Home Manager-generated shade-next fragment.
-- Loaded by: config/hammerspoon/shade_next.lua

return {
  app = {
    name = "shade-next",
    bundle_id = "io.shade.next",
    url_scheme = "shade-next://",
  },
  launch = {
    repo = "/Users/seth/code/shade-next",
    config = "/Users/seth/.config/shade-next/config.toml",
    socket = "/Users/seth/.local/state/shade-next/shade-next.sock",
    binaries = {
      debug = "/Users/seth/code/shade-next/.build/debug/shade-next",
      release = "/Users/seth/code/shade-next/.build/release/shade-next",
    },
  },
  chords = {
    toggle = { mods = { "cmd" }, key = "return" },
    search = { mods = { "cmd" }, key = "f" },
  },
  -- Keys inside the Hyper+n shade-next modal that launch/focus shade-next
  -- prefilled with a route.
  prefills = {
    { mods = { }, key = "p", route = "pi", focus = true },
    { mods = { }, key = "n", route = "note", focus = true },
  },
}
