if true then return {} end

local fmt = string.format

local default_prompt = Icons.misc.search .. "  "
local prompt = default_prompt

local function with_title(opts, rest)
  opts = opts or {}
  rest = rest or {}
  local path = opts.cwd or opts.path or rest.cwd or rest.path or nil
  local title = ""
  local buf_path = vim.fn.expand("%:p:h")
  local cwd = vim.fn.getcwd()

  if rest["title"] ~= nil then
    title = fmt("%s (%s):", rest.title, vim.fs.basename(path or vim.uv.cwd() or ""))
  else
    if path ~= nil and buf_path ~= cwd then
      title = require("plenary.path"):new(buf_path):make_relative(cwd)
    else
      title = vim.fn.fnamemodify(cwd, ":t")
    end
  end

  local title_config = vim.tbl_extend("force", opts, {
    title = title,
  }, rest or {})

  -- D(title_config)

  return title_config
end

local function ivy(opts)
  opts = opts or {}
  opts["winopts"] = opts.winopts or {}

  -- D({ opts.title, opts.winopts.title })
  local title = opts.winopts.title or opts.title

  local config = vim.tbl_deep_extend("force", {
    prompt = default_prompt,
    fzf_opts = { ["--layout"] = "reverse" },
    winopts = {
      title = title,
      title_pos = title and "center" or nil,
      height = 0.35,
      width = 1.00,
      row = 1,
      col = 1,
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      preview = {
        layout = "flex",
        hidden = "nohidden",
        flip_columns = 130,
        scrollbar = "float",
        scrolloff = "-1",
        scrollchars = { "█", "░" },
      },
    },
  }, opts)

  return config
end

local function dropdown(opts, ...)
  -- dd(I(opts))
  opts = opts or {}
  opts["winopts"] = opts.winopts or {}

  return vim.tbl_deep_extend("force", {
    -- prompt = ",
    fzf_opts = { ["--layout"] = "reverse" },
    winopts = {
      title_pos = opts["winopts"].title and "center" or nil,
      height = 0.70,
      width = 0.45,
      row = 0.1,
      col = 0.5,
      preview = { hidden = "hidden", layout = "vertical", vertical = "up:50%" },
    },
  }, opts, ...)
end

local function cursor_dropdown(opts)
  return dropdown({
    winopts = {
      row = 1,
      relative = "cursor",
      height = 0.33,
      width = 0.25,
    },
  }, opts)
end

local fzf = setmetatable({}, {
  __index = function(_, key)
    return function(topts)
      local topts = topts or {}
      local fzf_lua = require("fzf-lua")

      local get_selection = function()
        local rv = vim.fn.getreg("v")
        local rt = vim.fn.getregtype("v")
        vim.cmd([[noautocmd silent normal! "vy]])
        local selection = vim.fn.getreg("v")
        vim.fn.setreg("v", rv, rt)
        return vim.split(selection, "\n")
      end

      local mode = vim.api.nvim_get_mode().mode

      if mode == "v" or mode == "V" or mode == "" then topts.default_text = table.concat(get_selection()) end
      -- if key == "grepify" or key == "egrepify" then
      --   extensions("egrepify").egrepify(with_title(topts, { title = "live grep (egrepify)" }))
      -- elseif key == "undo" then
      --   extensions("undo").undo(big_ivy(with_title(topts, { title = "undo" })))
      -- elseif key == "smart_open" or key == "smart" then
      --   -- FIXME: if we have a title in topts, use that title with the default title
      --   local title = "smartly find files"
      --   -- if topts.title ~= nil then title = fmt("smartly find files (%s)", topts.title) end
      --   extensions("smart_open").smart_open(with_title(topts, { title = title }))
      -- elseif key == "grep" or key == "live_grep" then
      --   extensions("live_grep_args").live_grep_args(with_title(topts, { title = "live grep args" }))
      -- elseif key == "corrode" then
      --   extensions("corrode").corrode(with_title(topts, { title = "find files (corrode)" }))
      --   -- elseif key == "multi_rg" then
      --   --   multi_rg(with_title(topts, { title = "multi_rg" }))

      if key == "smart" then
        local opts = vim.tbl_deep_extend("force", topts, { title = "smart find" })
        require("fzf-lua-enchanted-files").files(with_title(opts))
        -- fzf_lua.global({
        --   pickers = function()
        --     local clients = fzf_lua.utils.lsp_get_clients({ bufnr = fzf_lua.utils.CTX().bufnr })
        --     local doc_sym_supported = vim.iter(clients):any(function(client)
        --       return client:supports_method("textDocument/documentSymbol")
        --     end)
        --     local wks_sym_supported = vim.iter(clients):any(function(client)
        --       return client:supports_method("workspace/symbol")
        --     end)
        --     return {
        --       -- { "frecency", desc = "Frecency" },
        --       -- { "combine", pickers = "frecency;files", desc = "Files" },
        --       { "files", desc = "Files" },
        --       { "frecency", desc = "Frecency", prefix = "%" },
        --       { "buffers", desc = "Buffers", prefix = "$" },
        --       doc_sym_supported and {
        --         "lsp_document_symbols",
        --         desc = "Symbols (buf)",
        --         prefix = "@",
        --         opts = { no_autoclose = true },
        --       } or {
        --         "btags",
        --         desc = "Tags (buf)",
        --         prefix = "@",
        --         opts = {
        --           previewer = { _ctor = require("fzf-lua.previewer").builtin.tags },
        --           fn_transform = [[return require("fzf-lua.make_entry").tag]],
        --         },
        --       },
        --       wks_sym_supported and {
        --         "lsp_workspace_symbols",
        --         desc = "Symbols (project)",
        --         prefix = "#",
        --         opts = { no_autoclose = true },
        --       } or {
        --         "tags",
        --         desc = "Tags (project)",
        --         prefix = "#",
        --         opts = {
        --           previewer = { _ctor = require("fzf-lua.previewer").builtin.tags },
        --           fn_transform = [[return require("fzf-lua.make_entry").tag]],
        --           rg_opts = "--no-heading --color=always --smart-case",
        --           grep_opts = "--color=auto --perl-regexp",
        --         },
        --       },
        --     }
        --   end,
        -- })
      elseif key == "files" then
        fzf_lua[key](with_title(topts, { title = "find files" }))
      else
        if topts["theme"] ~= nil then
          fzf_lua[key](topts)
        else
          fzf_lua[key](ivy(topts))
        end
      end
    end
  end,
})
------------------------------------------------------------------------------------------------------------------------
-- FZF-LUA HELPERS
------------------------------------------------------------------------------------------------------------------------

local function title(title, icon, opts)
  opts = opts or {}
  icon = icon or ""

  local path = opts.cwd or opts.path or nil
  local buf_path = vim.fn.expand("%:p:h")
  local cwd = vim.fn.getcwd()

  if title ~= nil then
    title = string.format("%s %s (%s)", icon, title, vim.fs.basename(path or vim.uv.cwd() or ""))
  else
    if path ~= nil and buf_path ~= cwd then
      title = require("plenary.path"):new(buf_path):make_relative(cwd)
    else
      title = vim.fn.fnamemodify(cwd, ":t")
    end
  end

  return title
end

local function file_picker(opts_or_cwd)
  if type(opts_or_cwd) == "table" then
    fzf.files(ivy(opts_or_cwd))
  else
    fzf.files(ivy({ cwd = opts_or_cwd }))
  end
end

local keys = {

  { "<leader>fa", "<Cmd>FzfLua<CR>", desc = "builtins" },
  {
    "<leader>ff",
    fzf.smart,
    -- function()
    --   -- fzf.combine({ pickers = "frecency;buffer" })
    -- end,
    desc = "find files",
  },
  { "<leader>fo", fzf.oldfiles, desc = "oldfiles" },
  { "<leader>fr", fzf.resume, desc = "resume picker" },
  { "<leader>fh", fzf.highlights, desc = "highlights" },
  { "<leader>fm", fzf.marks, desc = "marks" },
  { "<leader>fk", fzf.keymaps, desc = "keymaps" },
  { "<leader>flw", fzf.diagnostics_workspace, desc = "workspace diagnostics" },
  { "<leader>fls", fzf.lsp_document_symbols, desc = "document symbols" },
  { "<leader>flS", fzf.lsp_live_workspace_symbols, desc = "workspace symbols" },
  { "<leader>f?", fzf.help_tags, desc = "help" },
  { "<leader>fgb", fzf.git_branches, desc = "branches" },
  { "<leader>fgc", fzf.git_commits, desc = "commits" },
  { "<leader>fgB", fzf.git_bcommits, desc = "buffer commits" },
  { "<leader>fb", fzf.buffers, desc = "buffers" },
  { "<leader>a", fzf.live_grep_glob, desc = "live grep" },
  { "<leader>A", fzf.grep_cword, desc = "grep (under cursor)" },
  { "<leader>A", fzf.grep_visual, desc = "grep (visual selection)", mode = "v" },
  { "<leader>fva", fzf.autocmds, desc = "autocommands" },
  { "<leader>fp", fzf.registers, desc = "registers" },
  {
    "<leader>fd",
    function() file_picker(vim.env.DOTFILES) end,
    desc = "dotfiles",
  },
  {
    "<leader>fc",
    function() file_picker(vim.g.vim_path) end,
    desc = "nvim config",
  },

  -- {
  --   "<C-p>",
  --   function() require("fzf-lua-frecency").frecency({ display_score = true, cwd_only = true, fzf_opts = { ["--no-sort"] = false } }) end,
  --   desc = "Frecency (project)",
  -- },
  -- { "<leader>fH", function() require("fzf-lua-frecency").frecency({ display_score = true }) end, desc = "Frecency (All)" },
  -- {
  --   "<leader>fh",
  --   function() require("fzf-lua-frecency").frecency({ display_score = true, cwd_only = vim.fn.expand("$HOME") ~= vim.uv.cwd() and true }) end,
  --   desc = "Frecency (cwd)",
  -- },
}
-- table.insert(keys, { "<leader>sa", fzf.live_grep_glob, desc = "live grep" })

table.insert(keys, {
  "<c-p>",
  function()
    local actions = require("fzf-lua").actions

    fzf.smart({

      actions = {
        default = {
          ["default"] = actions.file_vsplit,
          ["ctrl-s"] = actions.file_split,
          ["ctrl-t"] = actions.file_tabedit,
          ["ctrl-o"] = actions.file_edit_or_qf,
          ["ctrl-i"] = actions.toggle_ignore,
          ["ctrl-h"] = actions.toggle_hidden,
          ["ctrl-q"] = actions.file_sel_to_qf,
          ["ctrl-l"] = actions.file_sel_to_ll,
          ["ctrl-g"] = actions.arg_add,
        },
      },
    })
    -- require("fzf-lua").global()
    -- FzfLua.global({
    --   pickers = function()
    --     local clients = FzfLua.utils.lsp_get_clients({ bufnr = FzfLua.utils.CTX().bufnr })
    --     local doc_sym_supported = vim.iter(clients):any(function(client)
    --       return client:supports_method("textDocument/documentSymbol")
    --     end)
    --     local wks_sym_supported = vim.iter(clients):any(function(client)
    --       return client:supports_method("workspace/symbol")
    --     end)
    --     return {
    --       { "frecency", desc = "Frecency" },
    --       { "buffers", desc = "Bufs", prefix = "$" },
    --       doc_sym_supported and {
    --         "lsp_document_symbols",
    --         desc = "Symbols (buf)",
    --         prefix = "@",
    --         opts = { no_autoclose = true },
    --       } or {
    --         "btags",
    --         desc = "Tags (buf)",
    --         prefix = "@",
    --         opts = {
    --           previewer = { _ctor = require("fzf-lua.previewer").builtin.tags },
    --           fn_transform = [[return require("fzf-lua.make_entry").tag]],
    --         },
    --       },
    --       wks_sym_supported and {
    --         "lsp_workspace_symbols",
    --         desc = "Symbols (project)",
    --         prefix = "#",
    --         opts = { no_autoclose = true },
    --       } or {
    --         "tags",
    --         desc = "Tags (project)",
    --         prefix = "#",
    --         opts = {
    --           previewer = { _ctor = require("fzf-lua.previewer").builtin.tags },
    --           fn_transform = [[return require("fzf-lua.make_entry").tag]],
    --           rg_opts = "--no-heading --color=always --smart-case",
    --           grep_opts = "--color=auto --perl-regexp",
    --         },
    --       },
    --     }
    --   end,
    -- })
  end,
  desc = "find files (smart)",
})

return {
  {
    "ibhagwan/fzf-lua",
    cmd = { "FzfLua" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      { "elanmed/fzf-lua-frecency.nvim", opts = {} },
      {
        "otavioschwanck/fzf-lua-enchanted-files",
        init = function()
          -- Modern configuration using vim.g
          vim.g.fzf_lua_enchanted_files = {
            history_file = vim.fn.stdpath("data") .. "/fzf-lua-enchanted-files-history.json",
            max_history_per_cwd = 50,
          }
        end,
      },
    },
    keys = keys,
    config = function()
      local lsp_kind = require("lspkind")
      local fzf_lua = require("fzf-lua")
      local actions = fzf_lua.actions

      fzf_lua.setup({
        { "ivy", "hide" },
        defaults = {
          file_icons = true,
        },
        fzf_opts = {
          ["--info"] = "default", -- hidden OR inline:⏐
          ["--reverse"] = false,
          ["--layout"] = "reverse", -- "default" or "reverse"
          ["--scrollbar"] = "▓",
          ["--ellipsis"] = Icons.misc.ellipsis,
        },
        winopts = {
          treesitter = {
            enabled = true,
          },
          title_pos = nil,
          height = 0.35,
          width = 1.00,
          row = 1,
          col = 1,
          border = "none",
          preview = {
            border = "rounded",
            layout = "flex",
            flip_columns = 130,
            scrollbar = "float",
            scrolloff = "-1",
            scrollchars = { "█", "░" },
          },
        },
        hls = {
          title = "TelescopeNormal",
          title_flags = "TelescopeNormal",
          normal = "TelescopeNormal",
          border = "TelescopeBorder",
          preview_normal = "TelescopePreviewNormal",
          preview_border = "TelescopePreviewBorder",
          preview_title = "TelescopePreviewTitle",
          scrollfloat_f = "TelescopeBorder",
          scrollborder_f = "TelescopePreviewNormal",
        },
        border = vim.g.border,
        title = "",
        previewers = {
          builtin = {
            toggle_behavior = "extend",
            syntax_limit_l = 0, -- syntax limit (lines), 0=nolimit
            syntax_limit_b = 1024 * 1024, -- syntax limit (bytes), 0=nolimit
            limit_b = 1024 * 1024 * 10, -- preview limit (bytes), 0=nolimit

            snacks_image = { enabled = false },
            -- extensions = {
            --   -- or, this is known to work: { "viu", "-t" }
            --   ["gif"] = { "chafa", "-c", "full" },
            --   ["jpg"] = { "chafa", "-c", "full" },
            --   ["jpeg"] = { "chafa", "-c", "full" },
            --   ["png"] = { "chafa", "-c", "full" },
            -- },
          },
        },
        keymap = {
          builtin = {
            ["<c-/>"] = "toggle-help",
            ["<c-=>"] = "toggle-fullscreen",
            ["<c-f>"] = "preview-page-down",
            ["<c-b>"] = "preview-page-up",
          },
          fzf = {
            ["esc"] = "abort",
          },
        },
        actions = {
          default = {
            ["default"] = actions.file_vsplit,
            ["ctrl-s"] = actions.file_split,
            ["ctrl-t"] = actions.file_tabedit,
            ["ctrl-o"] = actions.file_edit_or_qf,
            ["ctrl-i"] = actions.toggle_ignore,
            ["ctrl-h"] = actions.toggle_hidden,
            ["ctrl-q"] = actions.file_sel_to_qf,
            ["ctrl-l"] = actions.file_sel_to_ll,
            ["ctrl-g"] = actions.arg_add,
          },
          files = {
            ["default"] = actions.file_vsplit,
            ["ctrl-s"] = actions.file_split,
            ["ctrl-t"] = actions.file_tabedit,
            ["ctrl-o"] = actions.file_edit_or_qf,
            ["ctrl-i"] = actions.toggle_ignore,
            ["ctrl-h"] = actions.toggle_hidden,

            ["ctrl-q"] = actions.file_sel_to_qf,
            ["alt-q"] = actions.file_sel_to_ll,
            ["ctrl-x"] = actions.arg_add,
            ["ctrl-g"] = actions.arg_add,
            -- ["ctrl-l"] = { fn = actions.arg_add, exec_silent = true },
          },
          grep = {
            ["ctrl-i"] = actions.toggle_ignore,
            ["ctrl-h"] = actions.toggle_hidden,
            ["ctrl-o"] = actions.file_edit_or_qf,
            ["ctrl-l"] = actions.arg_add,
            ["ctrl-s"] = actions.file_split,
            ["default"] = actions.file_vsplit,
            ["ctrl-t"] = actions.file_tabedit,
            ["ctrl-q"] = actions.file_sel_to_qf,
            ["alt-q"] = actions.file_sel_to_ll,
            ["ctrl-g"] = "",
            ["ctrl-r"] = actions.grep_lgrep,
          },
        },
        frecency = {
          cwd_only = true,
          display_score = false,
        },
        highlights = {
          prompt = prompt,
          winopts = { title = title("highlights", "󰏘") },
        },
        helptags = {
          prompt = prompt,
          winopts = { title = title("help", "󰋖") },
        },
        oldfiles = dropdown({
          cwd_only = true,
          stat_file = true, -- verify files exist on disk
          include_current_session = false, -- include bufs from current session
          winopts = { title = title("history", "") },
        }),
        files = {
          multiprocess = true,
          prompt = prompt,
          winopts = { title = title("files", "") },
          -- previewer = "builtin",
          -- action = { ["ctrl-r"] = actions.arg_add },
        },
        buffers = dropdown({
          fzf_opts = { ["--delimiter"] = "' '", ["--with-nth"] = "-1.." },
          winopts = { title = title("buffers", "󰈙") },
        }),
        keymaps = dropdown({
          winopts = { title = title("keymaps", "") },
        }),
        registers = cursor_dropdown({
          winopts = { title = title("registers", ""), width = 0.6 },
        }),
        grep = ivy({
          multiprocess = true,
          fzf_opts = { ["--history"] = vim.fs.joinpath(vim.fn.stdpath("data"), "fzf_search_hist") },
          prompt = " ",
          winopts = { title = title("grep", "󰈭") },
          rg_opts = "--hidden --column --line-number --no-ignore-vcs --no-heading --color=always --smart-case -g '!.git'",
          rg_glob = true, -- enable glob parsing by default to all
          glob_flag = "--iglob", -- for case sensitive globs use '--glob'
          actions = { ["ctrl-g"] = actions.grep_lgrep },
          -- glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
          -- rg_glob_fn = function(query, opts)
          --   -- this enables all `rg` arguments to be passed in after the `--` glob separator
          --   local search_query, glob_str = query:match("(.*)" .. opts.glob_separator .. "(.*)")
          --   local glob_args = glob_str:gsub("^%s+", ""):gsub("-", "%-") .. " "

          --   return search_query, glob_args
          -- end,
          glob_separator = "  ",
          rg_glob_fn = function(query, opts)
            ---@type string, string
            local search_query, glob_args = query:match(("(.*)%s(.*)"):format(opts.glob_separator))
            return search_query, glob_args
          end,
          -- previewer = "builtin",
          -- fzf_opts = {
          --   ["--keep-right"] = "",
          -- },
        }),
        lsp = {
          cwd_only = true,
          -- symbols = {
          --   symbol_style = 1,
          --   symbol_icons = lsp_kind.symbols,
          --   symbol_hl = function(s) return mega.colors.lsp[s] end,
          -- },
          references = ivy({
            winopts = { title = title("references", "", "@type") },
          }),
          finder = {
            providers = {
              { "definitions", prefix = fzf_lua.utils.ansi_codes.green("def ") },
              { "declarations", prefix = fzf_lua.utils.ansi_codes.magenta("decl") },
              { "implementations", prefix = fzf_lua.utils.ansi_codes.green("impl") },
              { "typedefs", prefix = fzf_lua.utils.ansi_codes.red("tdef") },
              { "references", prefix = fzf_lua.utils.ansi_codes.blue("ref ") },
              { "incoming_calls", prefix = fzf_lua.utils.ansi_codes.cyan("in  ") },
              { "outgoing_calls", prefix = fzf_lua.utils.ansi_codes.yellow("out ") },
            },
          },
          symbols = {
            locate = true,
            -- symbol_style = 1,
            path_shorten = 1,
            -- symbol_icons = symbol_icons,
            symbol_icons = lsp_kind.symbols,
            -- symbol_hl = symbol_hl,
            symbol_hl = function(s) return mega.ui.colors.lsp[s] end,
            -- actions = { ["ctrl-g"] = false, ["ctrl-r"] = { fzf_lua.actions.sym_lsym } },
          },
          code_actions = {
            winopts = {
              relative = "cursor",
              row = 1,
              col = 0,
              height = 0.4,
              preview = { vertical = "down:70%" },
              title = title("code actions", "", "@type"),
            },
            previewer = vim.fn.executable("delta") == 1 and "codeaction_native" or nil,
            preview_pager = "delta --width=$COLUMNS --hunk-header-style=omit --file-style=omit",
          },
        },
        jumps = dropdown({
          winopts = { title = title("jumps", ""), preview = { hidden = "nohidden" } },
        }),
        changes = dropdown({
          prompt = "",
          winopts = { title = title("changes", "⟳"), preview = { hidden = "nohidden" } },
        }),
        diagnostics = ivy({
          winopts = { title = title("diagnostics", "", "DiagnosticError") },
        }),
        git = {
          files = dropdown({
            path_shorten = false, -- this doesn't use any clever strategy unlike telescope so is somewhat useless
            cmd = "git ls-files --others --cached --exclude-standard",
            winopts = { title = title("git files", "") },
          }),
          branches = dropdown({
            winopts = { title = title("branches", ""), height = 0.3, row = 0.4 },
          }),
          status = {
            prompt = "",
            preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
            winopts = { title = title("git status", "") },
          },
          bcommits = {
            prompt = "",
            preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
            winopts = { title = title("buffer commits", "") },
          },
          commits = {
            prompt = "",
            preview_pager = "delta --width=$FZF_PREVIEW_COLUMNS",
            winopts = { title = title("commits", "") },
          },
          icons = {
            ["M"] = { icon = Icons.git.mod, color = "yellow" },
            ["D"] = { icon = Icons.git.remove, color = "red" },
            ["A"] = { icon = Icons.git.add, color = "green" },
            ["R"] = { icon = Icons.git.rename, color = "yellow" },
            ["C"] = { icon = Icons.git.mod, color = "yellow" },
            ["T"] = { icon = Icons.git.mod, color = "magenta" },
            ["?"] = { icon = "?", color = "magenta" },
          },
        },
      })

      fzf.register_ui_select(dropdown({
        winopts = { title = title("select one of:"), height = 0.33, row = 0.5 },
      }))
    end,
  },
}
