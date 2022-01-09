local M = { pid = nil }

function M.getKittyApp()
  if M.pid then
    local app = hs.application.get(M.pid)
    if app and app:isRunning() then
      return app
    end
  end
  local f = io.popen("pgrep -af scratchpad")
  local ret = f:read("*a")
  f:close()
  M.pid = tonumber(ret)
  return M.pid and hs.application.get(M.pid)
end

M.toggle = function()
  local app = M.getKittyApp()
  if app then
    if app:isFrontmost() then
      print("kitty: hide")
      app:hide()
    else
      print("kitty: focus")
      local win = app:mainWindow()

      win:moveToScreen(1)
      win:focus()
    end
  else
    print("kitty: launch")
    os.execute(
      "/usr/local/bin/kitty -d ~ --title scratchpad -1 --instance-group scratchpad -o background_opacity=0.95 -o macos_hide_from_tasks=yes -o macos_quit_when_last_window_closed=yes &"
    )
    -- hs.execute(os.getenv("HOME") .. "/.dotfiles/bin/zetty", true)
  end
end

M.start = function()
  hs.hotkey.bindSpec(Config.quake, function()
    M.toggle()
  end)
end

M.stop = function() end

return M
