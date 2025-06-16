if not Plugin_enabled() then return end

mega.ui.tabline = {}

vim.o.showtabline = 2

local num_icons = {
  "󰎦 ",
  "󰎩 ",
  "󰎬 ",
  "󰎮 ",
  "󰎰 ",
  "󰎵 ",
  "󰎸 ",
  "󰎻 ",
  "󰎾 ",
  "󰽾 ",
}

-- highlighting -----------------------------
local function hl_str(hl, str) return "%#" .. hl .. "#" .. str .. "%*" end

function mega.ui.tabline.render()
  local current = vim.fn.tabpagenr()
  local total = vim.fn.tabpagenr("$")
  local out = {}

  for tab = 1, total do
    local hl = (tab == current) and "%#TabLineSel#" or "%#TabLine#"
    local icon = num_icons[tab] or tostring(tab)

    local names = {}
    for _, buf in ipairs(vim.fn.tabpagebuflist(tab)) do
      if vim.fn.buflisted(buf) == 1 then
        local n = vim.fn.bufname(buf)
        if n == "" then n = "[No Name]" end
        table.insert(names, vim.fn.fnamemodify(n, ":t"))
      end
    end
    table.insert(out, string.format("  %s %s%s ", hl, icon, table.concat(names, " ")))
  end

  return hl_str("TabLineFill", "  ") .. table.concat(out) .. "%#TabLineFill#"
end

-- vim.o.statusline = "%{%v:lua.mega.ui.tabline.render()%}"
vim.o.tabline = "%!v:lua.mega.ui.tabline.render()"
