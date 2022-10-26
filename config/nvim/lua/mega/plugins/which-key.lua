return function()
  local has_wk, wk = mega.require("which-key")
  if not has_wk then return end

  local fn = vim.fn
  local exec = mega.exec
  local api = vim.api
  -- NOTE: all convenience mode mappers are on the _G global; so no local assigns needed

  -- if you only want these mappings for toggle term use term://*toggleterm#* instead

  -- REF: predefine groups: https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/plugins/which-key/init.lua#L76-L90
  wk.setup({
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
    layout = {
      height = { min = 3, max = 25 }, -- min and max height of the columns
      width = { min = 10, max = 40 }, -- min and max width of the columns
      spacing = 3, -- spacing between columns
    },
    hidden = { ":w", "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
    show_help = true, -- show help message on the command line when the popup is visible
    triggers = "auto", -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specifiy a list manually
    --triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    -- 	i = { "j", "k" },
    -- 	v = { "j", "k" },
    -- },
  })

  local ok_gs, gs = mega.require("gitsigns")
  if ok_gs then
    require("which-key").register({
      g = {
        name = "git",
        g = { "<cmd>Git<CR>", "Fugitive" },
        H = "browse at line",
        O = "browse repo",
        B = "browse blame at line",
        r = {
          name = "+reset",
          e = "gitsigns: reset entire buffer",
        },
        b = {
          function() gs.blame_line({ full = true }) end,
          "gitsigns: blame current line",
        },
        h = {
          name = "+hunks",
          s = { gs.stage_hunk, "stage" },
          u = { gs.undo_stage_hunk, "undo stage" },
          r = { gs.reset_hunk, "reset hunk" },
          p = { gs.preview_hunk, "preview current hunk" },
          d = { gs.diffthis, "diff this line" },
          D = {
            function() gs.diffthis("~") end,
            "diff this with ~",
          },
          b = {
            name = "+blame",
            l = "gitsigns: blame current line",
            d = "gitsigns: toggle word diff",
            b = {
              function() gs.blame_line({ full = true }) end,
              "blame current line",
            },
          },
        },
        w = "gitsigns: stage entire buffer",
        m = "gitsigns: list modified in quickfix",
      },
    }, { prefix = "<leader>" })
  end

  -- Normal Mode {{{1
  local n_mappings = {
    ["[h"] = "go to prev git hunk",
    ["]h"] = "go to next git hunk",
    ["[d"] = "lsp: go to prev diagnostic",
    ["]d"] = "lsp: go to next diagnostic",
    -- f = {}, -- see plugins.lua > telescope-mappings
    ["<leader>c"] = {
      name = "+actions",
      d = { "telescope: diagnostics" },
      s = { "telescope: document symbols" },
      w = { "telescope: search workspace symbols" },
    },
    ["<leader>e"] = {
      name = "edit files",
      r = { [[<cmd>RenameFile<cr>]], "rename file to <input>" },
      s = { [[<cmd>SaveAsFile<cr>]], "save file as <input>" },
      d = { [[:DuplicateFile<cr>]], "duplicate current file" },
      D = { [[<cmd>Delete!<cr>]], "delete file" },
      yp = { [[:let @+ = expand("%")<CR>]], "yank path to clipboard" },
      t = { [[:Neotree toggle reveal<cr>]], "toggle neo-tree" },
    },
    ["<leader>f"] = {
      name = "telescope",
      B = { "builtins" },
      b = { "opened buffers" },
      -- b = { "current buffer fuzzy find" },
      d = { "dotfiles" },
      p = { "privates" },
      f = { "find/git files" },
      g = {
        name = "+git",
      },
      M = { "man pages" },
      m = { "oldfiles (mru)" },
      k = { "keymaps" },
      P = { "plugins" },
      -- o = { "buffers" },
      -- O = { "org files" },
      R = { "module reloader" },
      r = { "resume last picker" },
      s = { "grep string" },
      v = {
        name = "+vim",
        h = { "highlights" },
        a = { "autocommands" },
        o = { "options" },
      },
      t = {
        name = "+tmux",
        s = { "sessions" },
        w = { "windows" },
      },
      ["?"] = { "help" },
      h = { "help" },
    },
    ["<leader>l"] = {
      name = "+lsp",
      d = { "telescope: definitions" },
      D = { "telescope: diagnostics" },
      t = { "telescope: type definitions" },
      r = { "telescope: references" },
      s = { "telescope: document symbols" },
      S = { "telescope: workspace symbols" },
      w = { "telescope: dynamic workspace symbols" },
      n = { "lsp: rename" },
      i = { name = "lsp: info" },
    },
    ["<leader>m"] = {
      name = "markdown",
      p = { [[<cmd>MarkdownPreviewToggle<CR>]], "open preview" },
      g = { [[<cmd>Glow<CR>]], "open glow" },
    },
    ["<leader>p"] = {
      name = "project",
      p = { "<cmd>:AV<cr>", "Toggle Alternate (vsplit)" },
      P = { "<cmd>:A<cr>", "Open Alternate (edit)" },
      l = { "<cmd>:Vheex<cr>", "Open Heex for LiveView (vsplit)" },
      L = { "<cmd>:Vlive<cr>", "Open Live for LiveView (vsplit)" },
    },
    ["<leader>r"] = {
      name = " repls",
    },
    ["<leader>t"] = {
      name = "terminal",
      t = { "term" },
      f = { "term (float)" },
      v = { "term (vertical)" },
    },
    ["<leader>z"] = {
      name = "zk",
    },
    ["<localleader>t"] = {
      name = "test",
    },
    ["<localleader>d"] = {
      name = "debugger",
    },
    ["<localleader>g"] = {
      name = "git",
      r = {
        name = "gitsigns: reset hunk",
      },
      o = "gitlinker: open in browser",
      u = "gitlinker: copy to clipboard",
      s = "neogit: open status buffer",
      c = "neogit: open commit buffer",
      l = "neogit: open pull popup",
      p = "neogit: open push popup",
    },
    c = {
      name = "git-conflict",
      ["0"] = "Resolve with _None",
      t = "Resolve with _Theirs",
      o = "Resolve with _Ours",
      b = "Resolve with _Both",
      q = { "Send conflicts to _Quickfix" },
    },
    ["[c"] = { "<cmd>GitConflictPrevConflict<CR>", "go to prev conflict" },
    ["]c"] = { "<cmd>GitConflictNextConflict<CR>", "go to next conflict" },
    g = {
      name = "go-to",
      c = "comment text",
      ["cc"] = "comment line",
    },
    K = { "lsp: hover" },
    z = {
      name = "highlight/folds/paging",
      -- t = { [[<cmd>TSHighlightCapturesUnderCursor<CR>]], "show TS highlights under cursor" },
      -- TODO: ensure that we can get to these
      S = { "show syntax highlights under cursor" },
      s = { "show syntax highlights under cursor" },
      -- j = { mega.showCursorHighlights, "show syntax highlights under cursor" },
      -- S = {
      --   [[<cmd>lua require'nvim-treesitter-refactor.highlight_definitions'.highlight_usages(vim.fn.bufnr())<cr>]],
      --   "all usages under cursor",
      -- },
    },
  }
  -- }}}

  -- Visual Mode {{{1
  local v_mappings = {
    ["<leader>b"] = { name = "buffers", s = "save buffer" },
    ["<leader>f"] = { "format selection" },
    ["<leader>g"] = { name = "git link", y = "copy permalink selection" },
  }
  -- }}}

  wk.register(n_mappings, { mode = "n" })
  wk.register(v_mappings, { mode = "v" })
end
