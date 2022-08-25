local wt = require("wezterm")
local mux = wt.mux
local os = require("os")
local fmt = string.format
local palette = require("palette")

local function log(msg) wt.log_info(msg) end

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s) return string.gsub(s, "(.*[/\\])(.*)", "%2") end

local function notifier(opts)
  if opts.window == nil then return end

  opts = opts or {}
  local title = opts.title or "wezterm"
  local message = opts.message or ""
  local timeout = opts.timeout or 4000
  local window = opts.window

  window:toast_notification(title, message, nil, timeout)
end

wt.on(
  "window-config-reloaded",
  function(window, pane) notifier({ title = "wezterm", message = "configuration reloaded!", window = window, timeout = 4000 }) end
)

wt.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local dir = basename(pane.current_working_dir)
  local title = dir
  local icon = ""

  if dir == nil or dir == "" then title = basename(pane.foreground_process_name) end

  if dir == basename(wt.home_dir) then title = "~" end
  local tab_prefix = tab.tab_index == 0 and "  " or " "
  local tab_index = tab.tab_index + 1

  if tab.is_active then
    icon = tab.active_pane.is_zoomed and "" or ""
    -- tab_index = utf8.char(NUM_IDX_ACTIVE[tab.tab_index + 1])

    -- utf8.char(0xf490)
    return {
      { Text = tab_prefix },
      -- { Text = fmt("%s%s:%s ", icon, tab_index, title) },
      -- { Text = fmt("%s:%s ", tab.tab_index + 1, title) },
      { Text = fmt("%s %s:%s ", icon, tab_index, title) },
      { Text = "" },
    }
  end

  -- local has_unseen_output = false
  -- for _, pane in ipairs(tab.panes) do
  --   if pane.has_unseen_output then
  --     has_unseen_output = true
  --     break
  --   end
  -- end
  -- if has_unseen_output then
  --   return {
  --     { Background = { Color = "Orange" } },
  --     { Text = " " .. tab.active_pane.title .. " " },
  --   }
  -- end

  icon = tab.active_pane.is_zoomed and "" or ""
  return {
    { Text = tab_prefix },
    { Text = fmt("%s %s:%s ", icon, tab_index, title) },
    { Text = "" },
  }
end)

wt.on("update-right-status", function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  local config = window:effective_config()
  local session_color = palette.yellow
  local session_name = ""

  -- insert session name
  local session_icon = utf8.char(0xf490)
  for i, v in ipairs(config.unix_domains) do
    if v.name ~= nil and v.name ~= "" then
      session_name = v.name
      break
    else
      session_name = window:active_workspace()
    end
  end
  session_name = window:active_workspace()
  table.insert(
    cells,
    wt.format({
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { Color = session_color } },
      { Text = " " .. session_icon .. " " .. session_name },
    })
  )

  -- insert battery percentage
  for _, b in ipairs(wt.battery_info()) do
    table.insert(cells, fmt("%.0f%%", b.state_of_charge * 100))
  end

  -- insert local datetime and utc
  local datetime = fmt("%s (UTC %s)", wt.strftime("%H:%M"), wt.strftime_utc("%H:%M"))
  table.insert(cells, datetime)

  -- The elements to be formatted
  local formatted_cells = {}
  -- How many cells have been formatted
  local formatted_cells_count = 0
  -- Translate a cell into elements
  function push(text, is_last)
    table.insert(formatted_cells, { Text = "" .. text .. "" })
    if not is_last then table.insert(formatted_cells, { Text = " ⋮ " }) end
    formatted_cells_count = formatted_cells_count + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  -- push a spacer cell
  push(" ", #cells == 0)
  window:set_right_status(wt.format(formatted_cells))
end)
wt.on("trigger-nvim-with-scrollback", function(window, pane)
  local scrollback = pane:get_lines_as_text()
  local name = os.tmpname()
  local f = io.open(name, "w+")

  if f ~= nil then
    f:write(scrollback)
    f:flush()
    f:close()
    local command = "nvim " .. name
    window:perform_action(
      wt.action({ SpawnCommandInNewTab = {
        args = { "/usr/local/bin/zsh", "-l", "-c", command },
      } }),
      pane
    )
    wt.sleep_ms(1000)
    os.remove(name)
  end
end)

-- This produces a window split horizontally into three equal parts
wt.on("gui-startup", function(cmd)
  local args = {}
  if cmd then args = cmd.args end

  -- Set a workspace for coding on a current project
  -- Top pane is for the editor, bottom pane is for the build tool
  local project_dir = wt.home_dir .. "/.dotfiles"
  local tab, pane, window = mux.spawn_window({
    workspace = "mega",
    cwd = project_dir,
    args = args,
  })

  -- local editor_pane = pane:split({
  --   direction = "Top",
  --   size = 0.6,
  --   cwd = project_dir,
  -- })
  -- may as well kick off a build in that pane

  -- A workspace for interacting with a local machine that
  -- runs some docker containners for home automation
  -- local tab, pane, window = mux.spawn_window({
  --   workspace = "automation",
  --   args = { "ssh", "vault" },
  -- })

  wt.log_info("doing gui startup")
  -- We want to startup in the coding workspace
  mux.set_active_workspace("mega")
  window:gui_window():maximize()
end)

-- this is called by the mux server when it starts up.
-- It makes a window split top/bottom
wt.on("mux-startup", function()
  wt.log_info("doing mux startup")
  local tab, pane, window = mux.spawn_window({})
  window:gui_window():maximize()
  -- mux.split_pane(pane, { direction = "Top" })
end)
