-- golden-watch.lua: applies golden-ratio sizing (golden.lua) whenever a
-- session's layout or focus changes. Runs as `rex do --all golden-watch.lua`
-- from mise/scripts/rex-golden-launchd.
package.path = os.getenv("HOME") .. "/.config/rex/?.lua;" .. package.path
local golden = require("golden")

rex.on("session_view_changed", function(ctx)
  if golden.enabled() then
    golden.apply(ctx.session_id)
  end
end)
