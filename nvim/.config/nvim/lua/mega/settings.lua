return {
  activate = function()
    mega.inspect("activating package settings.lua..")

    local function set_indent_line()
      vim.g.indentLine_enabled = 1
      vim.g.indentLine_color_gui = '#556874'
      vim.g.indentLine_char = '│'
      vim.g.indentLine_bufTypeExclude = {'help', 'terminal', 'nerdtree', 'tagbar', 'startify', 'fzf'}
      vim.g.indentLine_bufNameExclude = {'_.*', 'NERD_tree.*', 'startify', 'fzf'}
      vim.g.indentLine_faster     = 1
      vim.g.indentLine_setConceal = 0
    end


    local function set_colorizer()
      local has_installed, p = pcall(require, "colorizer")
      if not has_installed then
        return
      end

      -- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
      p.setup({
        -- '*',
        -- '!vim',
        -- }, {
        css = {rgb_fn = true},
        scss = {rgb_fn = true},
        sass = {rgb_fn = true},
        stylus = {rgb_fn = true},
        vim = {names = false},
        tmux = {names = false},
        "eelixir",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "zsh",
        "sh",
        "conf",
        "lua",
        html = {
          mode = "foreground"
        }
      })
    end

    local function set_golden_ratio()
      local function ignore_by_buftype(types)
        local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
        for _, type in pairs(types) do
          if type == buftype then
            return 1
          end
        end
      end

      local golden_size = require("golden_size")
      -- set the callbacks, preserve the defaults
      golden_size.set_ignore_callbacks({
        {
          ignore_by_buftype,
          {
            "Undotree",
            "quickfix",
            "nerdtree",
            "current",
            "Vista",
            "LuaTree",
            "nofile"
          }
        },
        {golden_size.ignore_float_windows}, -- default one, ignore float windows
        {golden_size.ignore_by_window_flag} -- default one, ignore windows with w:ignore_gold_size=1
      })
    end

    local function set_fzf()
      vim.g.fzf_command_prefix = "Fzf"
      vim.g.fzf_layout = {window = {width = 0.6, height = 0.5}}
      vim.g.fzf_action = {enter = "vsplit"}
      vim.g.fzf_preview_window = {"right:50%", "alt-p"}
    end

    local function set_lsp_fuzzy()
      require("lspfuzzy").setup {}
    end

    local function set_sneak()
      vim.g["sneak#label"] = 1
      vim.g["sneak#s_next"] = 1
      vim.g["sneak#prompt"] = ""
    end

    local function set_textobj_parameter()
      vim.g.vim_textobj_parameter_mapping = ","
    end

    local function set_git_messenger()
      vim.g.git_messenger_no_default_mappings = true
      vim.g.git_messenger_max_popup_width = 100
      vim.g.git_messenger_max_popup_height = 100 

    end

    local function set_gitsigns()
      local has_installed, p = pcall(require, "gitsigns")
      if not has_installed then
        return
      end

      p.setup({
        signs = {
          add = {hl = "DiffAdd", text = "│"},
          change = {hl = "DiffChange", text = "│"},
          delete = {hl = "DiffDelete", text = "_"},
          topdelete = {hl = "DiffDelete", text = "‾"},
          changedelete = {hl = "DiffChange", text = "~"}
        },
        keymaps = {
          -- Default keymap options
          noremap = true,
          buffer = true,
          ["n ]g"] = {expr = true, '&diff ? \']g\' : \'<cmd>lua require"gitsigns".next_hunk()<CR>\''},
          ["n [g"] = {expr = true, '&diff ? \'[g\' : \'<cmd>lua require"gitsigns".prev_hunk()<CR>\''},
          ["n <leader>hs"] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
          ["n <leader>hu"] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
          ["n <leader>hr"] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
          ["n <leader>hp"] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
          ["n <leader>hb"] = '<cmd>lua require"gitsigns".blame_line()<CR>'
        },
        watch_index = {
          interval = 1000
        },
        sign_priority = 6,
        status_formatter = nil -- Use default
      })
    end

    local function set_delimit_mate()
      vim.g.delimitMate_expand_cr = 0
    end

    -- load'em up!

    set_golden_ratio()
    set_colorizer()
    set_gitsigns()
    set_indent_line()
    set_delimit_mate()
    set_git_messenger()
    set_textobj_parameter()
    set_sneak()
    set_fzf()
    set_lsp_fuzzy()
  end
}
