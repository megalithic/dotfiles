local M = {}

function M.hi(group, _fg, _bg, _style, _bang)
  local fg, bg, style, bang = "", "", "", ""

  if _fg ~= nil then
    fg = "guifg=" .. _fg
  end

  if _bg ~= nil then
    bg = "guibg=" .. _bg
  end

  if _style ~= nil then
    style = "gui=" .. _style
  end

  if _bang ~= nil and _bang then
    bang = "!"
  end

  vim.api.nvim_exec("highlight" .. bang .. " " .. group .. " " .. fg .. " " .. bg .. " " .. style, true)
end

-- return current background color
function M.get_background_color()
  local normal_bg = vim.fn.synIDattr(vim.fn.hlID("Normal"), "bg")
  if vim.fn.empty(normal_bg) then
    return "NONE"
  end
  return normal_bg
end

local function set_highlight(group, color)
  local fg, bg, style

  if type(color[1]) == "function" then
    if color[1]() ~= nil then
      fg = "guifg=" .. color[1]()
    else
      fg = "guifg=NONE"
    end
  else
    fg = color[1] and "guifg=" .. color[1] or "guifg=NONE"
  end

  if type(color[2]) == "function" then
    if color[2]() ~= nil then
      bg = "guibg=" .. color[2]()
    else
      bg = "guibg=NONE"
    end
  else
    bg = color[2] and "guibg=" .. color[2] or "guibg=NONE"
  end

  if type(color[3]) == "function" then
    style = "gui=" .. color[3]()
  else
    style = color[3] and "gui=" .. color[3] or " "
  end

  vim.api.nvim_command("highlight " .. group .. " " .. fg .. " " .. bg .. " " .. style)
end

function M.init_theme(theme_prefix, get_section)
  local section = get_section()
  local prefix = theme_prefix or "Nova"
  for pos, _ in pairs(section) do
    for _, comps in pairs(section[pos]) do
      for component_name, component_info in pairs(comps) do
        local highlight = component_info.highlight or {}
        local separator_highlight = component_info.separator_highlight or {}
        set_highlight(prefix .. component_name, highlight)

        if #separator_highlight ~= 0 then
          set_highlight(component_name .. "Separator", separator_highlight)
        end
      end
    end
  end
end

return M
