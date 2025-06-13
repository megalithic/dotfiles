local fmt = string.format
return {
  -- "folke/which-key.nvim",
  -- version = "2.1.0",
  cond = false,
  -- pin = true,
  -- event = "VeryLazy",
  "folke/which-key.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    preset = "modern",
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
    -- defer = { gc = "Comments" },
    replace = {
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
    -- window = { border = mega.get_border() },
    -- layout = { align = "center" },
    -- hidden = { ":w", "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
    show_help = true, -- show help message on the command line when the popup is visible
    triggers = "auto", -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specifiy a list manually
    -- triggers_blacklist = {
    --   n = { ":" },
    --   c = { ":" },
    -- },
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

    wk.add({
      ["<leader>n"] = { group = "[n]otes" },
      ["<leader>c"] = { group = "[c]ode" },
      ["<leader>d"] = { group = "[d]ocument" },
      ["<leader>e"] = { group = "[e]dit files", { x = { group = "e[x]ecute" } } },
      ["<leader>f"] = {
        group = "[f]ind (" .. vim.g.picker .. ")",
        _ = "which_key_ignore",
      },
      ["<leader>l"] = {
        group = "[l]sp",
        c = { group = "[c]ode [a]ctions" },
        i = { group = "[i]nfo" },
        s = { group = "[s]ymbols" },
        -- w = { name = "[w]orkspace" },
        _ = "which_key_ignore",
      },
      ["<leader>g"] = { group = "[g]it", _ = "which_key_ignore" },
      ["<leader>p"] = { group = "[p]lugins", _ = "which_key_ignore" },
      ["<leader>r"] = { group = "[r]ename", _ = "which_key_ignore" },
      ["<leader>t"] = { group = "[t]erminal", _ = "which_key_ignore" },
      ["<leader>z"] = { group = "[z]k", _ = "which_key_ignore" },
      ["<localleader>d"] = { group = "[d]ebug", _ = "which_key_ignore" },
      ["<localleader>g"] = { group = "[g]it", _ = "which_key_ignore" },
      ["<localleader>h"] = { group = "[h]unk", _ = "which_key_ignore" },
      ["<localleader>r"] = { group = "[r]epl", _ = "which_key_ignore" },
      ["<localleader>t"] = { group = "[t]est", _ = "which_key_ignore" },
      ["<localleader>s"] = { group = "[s]pell", _ = "which_key_ignore" },

      -- { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
      -- { "<leader>fb", function() print("hello") end, desc = "Foobar" },
      -- { "<leader>fn", desc = "New File" },
      -- { "<leader>f1", hidden = true }, -- hide this keymap
      -- -- { "<leader>w", proxy = "<c-w>", group = "windows" }, -- proxy to window mappings
      -- { "<leader>b", group = "buffers", expand = function()
      --     return require("which-key.extras").expand.buf()
      --   end
      -- },
      -- {
      --   -- Nested mappings are allowed and can be added in any order
      --   -- Most attributes can be inherited or overridden on any level
      --   -- There's no limit to the depth of nesting
      --   mode = { "n", "v" }, -- NORMAL and VISUAL mode
      --   { "<leader>q", "<cmd>q<cr>", desc = "Quit" }, -- no need to specify mode since it's inherited
      --   { "<leader>w", "<cmd>w<cr>", desc = "Write" },
      -- }
    })
    -- wk.register({
    --   ["<leader>n"] = { name = "[n]otes", _ = "which_key_ignore" },
    --   ["<leader>c"] = { name = "[c]ode", _ = "which_key_ignore" },
    --   ["<leader>d"] = { name = "[d]ocument", _ = "which_key_ignore" },
    --   ["<leader>e"] = {
    --     name = "+edit files",
    --     r = { function() require("config.utils").lsp.rename_file() end, "rename file (lsp) to <input>" },
    --     s = { [[<cmd>SaveAsFile<cr>]], "save file as <input>" },
    --     e = "oil: open (edit)", -- NOTE: change in plugins/extended/oil.lua
    --     v = "oil: open (vsplit)", -- NOTE: change in plugins/extended/oil.lua
    --     n = "notes: open notes dir in tmux split",
    --     t = "tmux: open current file's dir in tmux split",
    --     f = { function() vim.ui.open(vim.fn.expand("%:p:h:~")) end, "finder: open current file's directory in finder" },
    --     d = {
    --       function()
    --         if vim.fn.confirm("Duplicate file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Duplicate") end
    --       end,
    --       "duplicate file?",
    --     },
    --     D = {
    --       function()
    --         if vim.fn.confirm("Delete file?", "&Yes\n&No", 2, "Question") == 1 then vim.cmd("Delete!") end
    --       end,
    --       "delete file?",
    --     },
    --     yp = {
    --       function()
    --         vim.cmd([[let @+ = expand("%")]])
    --         vim.notify(fmt("yanked %s to clipboard", vim.fn.expand("%")))
    --       end,
    --       "yank path to clipboard",
    --     },
    --     xf = "execute file",
    --     xl = "execute line",
    --   },
    --   ["<leader>f"] = {
    --     name = "[f]ind (" .. vim.g.picker .. ")",
    --     _ = "which_key_ignore",
    --   },
    --   ["<leader>l"] = {
    --     name = "[l]sp",
    --     c = { name = "[c]ode [a]ctions" },
    --     i = { name = "[i]nfo" },
    --     s = { name = "[s]ymbols" },
    --     -- w = { name = "[w]orkspace" },
    --     _ = "which_key_ignore",
    --   },
    --   ["<leader>g"] = { name = "[g]it", _ = "which_key_ignore" },
    --   ["<leader>p"] = { name = "[p]lugins", _ = "which_key_ignore" },
    --   ["<leader>r"] = { name = "[r]ename", _ = "which_key_ignore" },
    --   ["<leader>t"] = { name = "[t]erminal", _ = "which_key_ignore" },
    --   ["<leader>z"] = { name = "[z]k", _ = "which_key_ignore" },
    --   ["<localleader>d"] = { name = "[d]ebug", _ = "which_key_ignore" },
    --   ["<localleader>g"] = { name = "[g]it", _ = "which_key_ignore" },
    --   ["<localleader>h"] = { name = "[h]unk", _ = "which_key_ignore" },
    --   ["<localleader>r"] = { name = "[r]epl", _ = "which_key_ignore" },
    --   ["<localleader>t"] = { name = "[t]est", _ = "which_key_ignore" },
    --   ["<localleader>s"] = { name = "[s]pell", _ = "which_key_ignore" },
    -- })
  end,
}
