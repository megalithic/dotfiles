-- lua/plugins/whichkey.lua
-- Key hint popup with helix-style bottom-right layout

--- Add plugin-specific groups from plugin configs (deferred)
--- Usage in plugin spec: vim.g.whichkeyAddSpec({ "<leader>x", group = "foo" })
---@param spec { [1]: string, mode?: string[], group: string }
vim.g.whichkeyAddSpec = function(spec)
  if not spec.mode then spec.mode = { "n", "x" } end
  vim.defer_fn(function()
    local ok, whichkey = pcall(require, "which-key")
    if ok and whichkey then whichkey.add(spec) end
  end, 1000)
end

return {
  "folke/which-key.nvim",
  cond = function() return vim.g.keyhelper == "whichkey" end,
  event = "VeryLazy",
  keys = {
    {
      "<localleader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "buffer local keymaps (wk)",
    },
    {
      "<leader>?",
      function() require("which-key").show({ global = true }) end,
      desc = "global keymaps (wk)",
    },
  },
  opts = {
    delay = 400,
    preset = "helix",

    win = {
      border = vim.g.border_style or "rounded",
      height = { min = 1, max = 0.95 },
      padding = { 1, 2 },
    },

    spec = {
      {
        mode = { "n", "x" },
        -- Root groups
        { "<leader>", group = "leader" },
        { "<localleader>", group = "local" },

        -- Leader subgroups
        { "<leader>f", group = "pick" },
        { "<leader>t", group = "term" },
        { "<leader>g", group = "git" },
        { "<leader>l", group = "lsp" },
        { "<leader>p", group = "plugins" },
        { "<leader>u", group = "ui/toggle" },
        { "<leader>x", group = "trouble" },

        -- Localleader subgroups
        { "<localleader>p", group = "pi" },
        { "<localleader>pA", group = "acp" },
        { "<localleader>t", group = "test" },
        { "<localleader>r", group = "repl" },

        -- Goto and motion groups
        { "g", group = "goto" },
        { "z", group = "folds/spelling" },
        { "[", group = "prev" },
        { "]", group = "next" },
      },

      -- Text objects
      {
        mode = { "o", "x" },
        { "i", group = "inner" },
        { "a", group = "outer" },
        { "g", group = "misc" },
        { "ip", desc = "paragraph" },
        { "ap", desc = "paragraph" },
        { "ib", desc = "bracket" },
        { "ab", desc = "bracket" },
        { "it", desc = "tag" },
        { "at", desc = "tag" },
        { "is", desc = "sentence" },
        { "as", desc = "sentence" },
        { "iw", desc = "word" },
        { "aw", desc = "word" },
        { "gn", desc = "search result" },
      },
    },

    plugins = {
      marks = true,
      registers = true,
      spelling = { enabled = true, suggestions = 20 },
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },

    -- Filter out nvim builtins and mappings without descriptions
    filter = function(map)
      local nvim_builtins = {
        "<C-W><C-D>",
        "<C-W>d",
        "gc",
        "gcc",
        "gra",
        "gri",
        "grn",
        "grr",
        "grt",
        "g~",
        "gO",
      }
      if vim.list_contains(nvim_builtins, map.lhs) then return false end
      return map.desc ~= nil
    end,

    replace = {
      desc = {
        { " outer ", " " },
        { " inner ", " " },
        { " rest of ", " " },
        { "LSP: ", "" },
        { "pick: ", "" },
      },
    },

    icons = {
      group = "",
      separator = "│",
      mappings = false,
      keys = {
        Up = " ",
        Down = " ",
        Left = " ",
        Right = " ",
        C = "󰘴 ",
        M = "󰘵 ",
        D = "󰘳 ",
        S = "󰘶 ",
        CR = "󰌑 ",
        Esc = "󱊷 ",
        ScrollWheelDown = "󱕐 ",
        ScrollWheelUp = "󱕑 ",
        NL = "󰌑 ",
        BS = "󰁮",
        Space = "󱁐 ",
        Tab = "󰌒 ",
        PageDown = "󰇚",
        PageUp = "󰸇",
      },
    },

    keys = {
      scroll_down = "<C-d>",
      scroll_up = "<C-u>",
    },

    sort = { "local", "order", "group", "alphanum", "mod" },
    expand = 0,
    show_help = false,
  },

  config = function(_, opts)
    -- Add count to whichkey groups
    local orig_view_item = require("which-key.view").item
    require("which-key.view").item = function(node, view_opts)
      local count = node:count()
      if node.desc and count > 0 and not vim.endswith(node.desc, ")") then
        node.desc = ("%s (%d)"):format(node.desc, count)
      end
      return orig_view_item(node, view_opts)
    end

    require("which-key").setup(opts)
  end,
}
