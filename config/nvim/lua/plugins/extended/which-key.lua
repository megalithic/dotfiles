local fmt = string.format
return {
  "folke/which-key.nvim",
  version = "2.1.0",
  pin = true,
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    -- preset = "modern",
    plugins = {
      marks = true, -- shows a list of your marks on ' and `
      registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      -- the presets plugin, adds help for a bunch of default keybindings in Neovim
      -- No actual key bindings are created
      spelling = {
        enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
        suggestions = 20, -- how many suggestions should be shown in the list?
      },
      presets = {
        operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
        motions = false, -- adds help for motions
        text_objects = true, -- help for text objects triggered after entering an operator
        windows = false, -- default bindings on <c-w>
        nav = true, -- misc bindings to work with windows
        z = true, -- bindings for folds, spelling and others prefixed with z
        g = true, -- bindings for prefixed with g
      },
    },
    -- add operators that will trigger motion and text object completion
    -- to enable all native operators, set the preset / operators plugin above
    operators = { gc = "Comments" },
    key_labels = {
      -- override the label used to display some keys. It doesn't effect WK in any other way.
      -- For example:
      ["<space>"] = "SPC",
      ["<cr>"] = "RET",
      ["<tab>"] = "TAB",
    },
    icons = {
      breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
      separator = "➜", -- symbol used between a key and it's label
      group = "+", -- symbol prepended to a group
    },
    window = {
      border = "none", -- none, single, double, shadow
      position = "bottom", -- bottom, top
      margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
      padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
    },
    -- window = { border = mega.get_border() },
    -- layout = { align = "center" },
    hidden = { ":w", "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
    show_help = true, -- show help message on the command line when the popup is visible
    triggers = "auto", -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specifiy a list manually
    triggers_blacklist = {
      n = { ":" },
      c = { ":" },
    },
  },
  config = function(_, opts) -- This is the function that runs, AFTER loading
    local wk = require("which-key")
    wk.setup(opts)
    -- wk.add({
    --   { "<leader>c", group = "[c]ode" },
    --   { "<leader>d", group = "[d]ocument" },
    --   { "<leader>e", group = "[e]dit files" },
    --   { "<leader>e", group = "[e]dit files" },
    -- })

    -- Document existing key chains
    wk.register({
      ["<leader>c"] = { name = "[c]ode", _ = "which_key_ignore" },
      ["<leader>d"] = { name = "[d]ocument", _ = "which_key_ignore" },
      ["<leader>e"] = {
        name = "+edit files",
        r = { function() require("mega.utils").lsp.rename_file() end, "rename file (lsp) to <input>" },
        s = { [[<cmd>SaveAsFile<cr>]], "save file as <input>" },
        e = "oil: open (edit)", -- NOTE: change in plugins/extended/oil.lua
        v = "oil: open (vsplit)", -- NOTE: change in plugins/extended/oil.lua
        n = "notes: open notes dir in tmux split",
        t = "tmux: open current file's dir in tmux split",
        d = {
          function()
            if vim.fn.confirm("Duplicate file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Duplicate") end
          end,
          "duplicate file?",
        },
        D = {
          function()
            if vim.fn.confirm("Delete file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Delete!") end
          end,
          "delete file?",
        },
        yp = {
          function()
            vim.cmd([[let @+ = expand("%")]])
            vim.notify(fmt("yanked %s to clipboard", vim.fn.expand("%")))
          end,
          "yank path to clipboard",
        },
        xf = "execute file",
        xl = "execute line",
      },

      ["<leader>f"] = {
        name = "[f]ind (" .. vim.g.picker .. ")",
        _ = "which_key_ignore",
      },
      ["<leader>l"] = {
        name = "[l]sp",
        c = { name = "[c]ode [a]ctions" },
        i = { name = "[i]nfo" },
        s = { name = "[s]ymbols" },
        -- w = { name = "[w]orkspace" },
        _ = "which_key_ignore",
      },
      ["<leader>g"] = { name = "[g]it", _ = "which_key_ignore" },
      ["<leader>n"] = { name = "[n]otes", _ = "which_key_ignore" },
      ["<leader>p"] = { name = "[p]lugins", _ = "which_key_ignore" },
      ["<leader>r"] = { name = "[r]ename", _ = "which_key_ignore" },
      ["<leader>t"] = { name = "[t]erminal", _ = "which_key_ignore" },
      ["<leader>z"] = { name = "[z]k", _ = "which_key_ignore" },
      ["<localleader>d"] = { name = "[d]ebug", _ = "which_key_ignore" },
      ["<localleader>g"] = { name = "[g]it", _ = "which_key_ignore" },
      ["<localleader>h"] = { name = "[h]unk", _ = "which_key_ignore" },
      ["<localleader>r"] = { name = "[r]epl", _ = "which_key_ignore" },
      ["<localleader>t"] = { name = "[t]est", _ = "which_key_ignore" },
      ["<localleader>s"] = { name = "[s]pell", _ = "which_key_ignore" },
    })
  end,
}
