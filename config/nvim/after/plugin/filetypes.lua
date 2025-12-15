if not Plugin_enabled() then return end

---@param text string
---@param replace string
local function abbr(text, replace, bufnr) vim.keymap.set("ia", text, replace, { buffer = bufnr or true }) end

require("config.ftplugin").extend_all({
  -- dbee = {
  --   keys = {
  --     { "n", "H", "^" },
  --     { "n", "L", "$" },
  --     -- map("n", "H", "^")
  --     -- map("n", "L", "$")
  --     -- map({ "v", "x" }, "L", "g_")
  --     -- map("n", "0", "^")
  --   },
  -- },
  cmdline = {
    opt = {
      number = false,
      relativenumber = false,
    },
  },
--  [{ "cmd", "msg", "pager", "dialog" }] = {
--
--    opt = {
--      signcolumn = false,
--      number = false,
--      relativenumber = false,
--    },
--    callback = function(bufnr, args)
--      vim.api.nvim_set_option_value("winhl", "Normal:PanelBackground,FloatBorder:PanelBorder", {})
--    end,
--  },
  [{ "elixir", "eelixir" }] = {
    opt = {
      syntax = "OFF",
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[# %s]],
    },
    abbr = {
      ep = "|>",
      epry = [[require IEx; IEx.pry]],
      ei = [[IO.inspect()<ESC>hi]],
      eputs = [[IO.puts()<ESC>hi]],
      edb = [[dbg()<ESC>hi]],
      ["~H"] = [[~H""""""<ESC>2hi<CR><ESC>O<BS> ]],
      ["~h"] = [[~H""""""<ESC>2hi<CR><ESC>O<BS> ]],
      [":skip:"] = "@tag :skip",
      tskip = "@tag :skip",
    },
    -- opt = {
    --   iskeyword = vim.opt.iskeyword + { "!", "?", "-" },
    --   indentkeys = vim.opt.indentkeys + { "end" },
    -- },
    callback = function(bufnr, args)
      -- TODO:
      -- very handle to/from_pipe macros: https://github.com/pejrich/nvim_config/blob/master/lua/utils.lua#L146-L208
      --
      -- REF:
      -- running tests in iex:
      -- https://www.elixirstreams.com/tips/test-breakpoints
      -- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar
      vim.cmd([[setlocal iskeyword+=!,?,-]])
      vim.cmd([[setlocal indentkeys-=0{]])
      vim.cmd([[setlocal indentkeys+=0=end]])

      -- mega.command("CopyModuleAlias", function()
      --   vim.api.nvim_feedkeys(
      --     -- Copy Module Alias to next window? [[mT?defmodule <cr>w"zyiW`T<c-w>poalias <c-r>z]]
      --     vim.api.nvim_replace_termcodes([[mT?defmodule <cr>w"zyiW`Tpoalias <c-r>z]], true, false, true),
      --     "n",
      --     true
      --   )
      -- end)

      local nmap = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = "ex: " .. desc }) end
      local xmap = function(lhs, rhs, desc) vim.keymap.set("x", lhs, rhs, { buffer = 0, desc = "ex: " .. desc }) end
      nmap("<localleader>ep", [[o|><ESC>a]], "pipe (new line)")
      nmap("<localleader>ed", [[o|> dbg()<ESC>a]], "dbg (new line)")
      nmap("<localleader>ei", [[o|> IO.inspect()<ESC>i]], "inspect (new line)")
      nmap("<localleader>eil", [[o|> IO.inspect(label: "")<ESC>hi]], "inspect label (new line)")
      nmap("<localleader>em", "<cmd>CopyModuleAlias<cr>", "copy module alias")
      nmap("<localleader>eF", function()
        vim.cmd("silent !mix format")
        vim.cmd("edit")
      end, "format")

      nmap("<localleader>ok", [[:lua require("config.utils").wrap_cursor_node("{:ok, ", "}")<CR>]], "copy module alias")
      xmap(
        "<localleader>ok",
        [[:lua require("config.utils").wrap_selected_nodes("{:ok, ", "}")<CR>]],
        "copy module alias"
      )
      nmap(
        "<localleader>err",
        [[:lua require("config.utils").wrap_cursor_node("{:error, ", "}")<CR>]],
        "copy module alias"
      )
      xmap(
        "<localleader>err",
        [[:lua require("config.utils").wrap_selected_nodes("{:error, ", "}")<CR>]],
        "copy module alias"
      )

      -- NOTE: these workspace commands only work with elixir-ls
      -- local lsp_execute = function(opts)
      --   local params = {
      --     command = opts.command,
      --     arguments = opts.arguments,
      --   }
      --   vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
      -- end
      -- nmap("<localleader>ePt", function()
      --   local params = vim.lsp.util.make_position_params()
      --   lsp_execute({
      --     command = "manipulatePipes:serverid",
      --     arguments = { "toPipe", params.textDocument.uri, params.position.line, params.position.character },
      --   })
      -- end, "pipes: to pipe")
      -- nmap("<localleader>ePf", function()
      --   local params = vim.lsp.util.make_position_params()
      --   lsp_execute({
      --     command = "manipulatePipes:serverid",
      --     arguments = { "fromPipe", params.textDocument.uri, params.position.line, params.position.character },
      --   })
      -- end, "pipes: from pipe")

      if vim.g.tester == "vim-test" then
        nmap("<localleader>td", function()
          local function elixir_dbg_transform(cmd)
            -- local modified_cmd = cmd:gsub("^mix%s*", "")
            -- local returned_cmd = "MIX_ENV=test iex --dbg pry -S mix do " .. modified_cmd .. " --trace + run -e 'System.halt'"
            local returned_cmd = string.format("iex -S %s -b", cmd)

            return returned_cmd
          end
          vim.g["test#custom_transformations"] = { elixir = elixir_dbg_transform }
          vim.g["test#transformation"] = "elixir"
          vim.cmd("TestNearest")
        end, "[d]ebug [n]earest test")
      end

      if pcall(require, "mini.clue") then
        vim.b.miniclue_config = {
          clues = {
            { mode = "n", keys = "<localleader>e", desc = "+elixir" },
            { mode = "n", keys = "<localleader>eP", desc = "+elixir -> pipes" },
          },
        }
      end

      -- Inside an attribute: <button type| pressing = -> <button type="|"
      vim.keymap.set("i", "=", function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local left_of_cursor_range = { cursor[1] - 1, cursor[2] - 1 }

        local current_node = vim.treesitter.get_node({ ignore_injections = false, pos = left_of_cursor_range })
        local html_attr_node = require("config.utils").ts.find_node_ancestor(
          { "attribute_name", "directive_argument", "directive_name" },
          current_node
        )

        if html_attr_node then
          return '={""}<left><left>'
        else
          return "="
        end
      end, { expr = true, buffer = bufnr })

      vim.keymap.set("n", "<localleader>ic", function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local left_of_cursor_range = { cursor[1] - 1, cursor[2] - 1 }

        local lang_tree = require("config.utils").ts.get_language_tree_for_cursor_location()
        local tree = lang_tree:parse()[1]
        local lang = tree._lang

        local current_node = vim.treesitter.get_node({ ignore_injections = false, pos = left_of_cursor_range })
        local html_attr_node = require("config.utils").ts.find_node_ancestor(
          { "attribute_name", "directive_argument", "directive_name" },
          current_node
        )

        -- local buf_lang = vim.treesitter.language.get_lang(vim.bo[0].filetype)
        -- local ok_parser, parser = pcall(vim.treesitter.get_string_parser, text, buf_lang)

        -- local function include_language_tree(root_lang, lang)
        --   -- We should not attempt to format html inside markdown
        --   -- See https://github.com/stevearc/conform.nvim/issues/485
        --   if root_lang == "markdown" and lang == "html" then return false end
        --   -- Don't format the root language with the injected formatter
        --   return root_lang ~= lang
        -- end

        -- local function accum_range(ranges, range)
        --   local last_range = ranges[#ranges]
        --   if last_range then
        --     if last_range[1] == range[1] and last_range[4] == range[2] and last_range[5] == range[3] then
        --       last_range[4] = range[4]
        --       last_range[5] = range[5]
        --       return
        --     end
        --   end
        --   table.insert(ranges, range)
        -- end

        -- if ok_parser then
        --   parser:parse(true)
        --   local root_lang = parser:lang()
        --   ---@type LangRange[]
        --   local regions = {}

        --   for lang, lang_tree in pairs(parser:children()) do
        --     if include_language_tree(root_lang, lang) then
        --       for _, ranges in ipairs(lang_tree:included_regions()) do
        --         for _, region in ipairs(ranges) do
        --           local start_row, start_col, _, end_row, end_col, _ = unpack(region)
        --           accum_range(regions, { lang, start_row + 1, start_col, end_row + 1, end_col })

        --           -- local formatters = get_formatters(lang)
        --           -- if formatters == nil then
        --           --   log.info("No formatters found for injected treesitter language %s", lang)
        --           -- else
        --           --   -- The types are wrong. included_regions should be Range[][] not integer[][]
        --           --   ---@diagnostic disable-next-line: param-type-mismatch
        --           --   local start_row, start_col, _, end_row, end_col, _ = unpack(region)
        --           --   accum_range(regions, { lang, start_row + 1, start_col, end_row + 1, end_col })
        --           -- end
        --         end
        --       end
        --     end
        --   end

        --   -- regions = merge_ranges_with_prefix(regions, ctx.buf, buf_lang)

        --   --     if ctx.range then
        --   --       regions = vim.tbl_filter(function(region)
        --   --         return in_range(ctx.range, region[2], region[4])
        --   --       end, regions)
        --   --     end

        --   --     -- Sort from largest start_lnum to smallest
        --   --     table.sort(regions, function(a, b)
        --   --       return a[2] > b[2]
        --   --     end)
        --   D("Injected formatter regions %s", regions)
        -- end

        local contents = {}

        table.insert(contents, string.format("lang: %s", lang))
        table.insert(contents, string.format("node named: %s", current_node:named()))
        table.insert(contents, string.format("node type: %s", current_node:type()))
        table.insert(contents, string.format("parent_node type: %s", current_node:parent():type()))

        -- P(contents)

        -- table.insert(contents, {
        --   filename = "language tree:",
        --   text = lang,
        --   type = "I",
        --   valid = 1,
        --   -- lnum = cursor[1],
        -- })
        -- table.insert(contents, {
        --   filename = "node type:",
        --   text = current_node:type(),
        --   type = "I",
        --   valid = 1,
        --   -- lnum = cursor[1],
        -- })
        -- table.insert(contents, {
        --   filename = "parent node type: ",
        --   text = current_node:parent():type(),
        --   type = "I",
        --   valid = 1,
        --   -- lnum = cursor[1],
        -- })

        local popup_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = popup_bufnr })
        vim.api.nvim_set_option_value("buftype", "prompt", { buf = popup_bufnr })
        vim.api.nvim_set_option_value("filetype", "prompt", { buf = popup_bufnr })
        local BORDER_STYLE = require("config.options").border
        local winnr = vim.api.nvim_open_win(popup_bufnr, true, {
          relative = "cursor",
          width = 30,
          height = 5,
          row = -3,
          col = 1,
          style = "minimal",
          border = BORDER_STYLE,
        })

        vim.api.nvim_set_option_value(
          "winhl",
          table.concat({
            "Normal:NormalFloat",
            "FloatBorder:FloatBorder",
            "CursorLine:Visual",
            "Search:None",
          }, ","),
          { win = winnr }
        )

        vim.keymap.set({ "n", "i" }, "<esc>", function()
          vim.api.nvim_win_close(winnr or 0, true)
          vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "i", true)
        end, { buffer = popup_bufnr })

        vim.keymap.set({ "n", "i" }, "<c-c>", function()
          vim.api.nvim_win_close(winnr or 0, true)
          vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "i", true)
        end, { buffer = popup_bufnr })

        -- vim.fn.setqflist(contents, "r")
        -- vim.cmd("copen")
        -- vim.cmd("Trouble open")

        -- local Popup = require("nui.popup")
        -- local event = require("nui.utils.autocmd").event

        -- local popup = Popup({
        --   enter = true,
        --   focusable = true,
        --   border = {
        --     style = "rounded",
        --   },
        --   relative = "cursor",
        --   size = {
        --     width = "40%",
        --     height = "40%",
        --   },
        -- })

        -- -- mount/open the component
        -- popup:mount()

        -- -- unmount component when cursor leaves buffer
        -- popup:on(event.BufLeave, function() popup:unmount() end)

        -- -- set content
        vim.api.nvim_buf_set_lines(popup_bufnr, 0, 1, false, contents)
      end, { buffer = bufnr })
    end,
  },
  heex = {
    opt = {
      syntax = "OFF",
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[<%!-- %s --%>]],
    },
    callback = function(bufnr, args)
      vim.bo[bufnr].commentstring = [[<%!-- %s --%>]]

      vim.keymap.set("i", "=", function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local left_of_cursor_range = { cursor[1] - 1, cursor[2] - 1 }

        local current_node = vim.treesitter.get_node({ ignore_injections = false, pos = left_of_cursor_range })
        local html_attr_node = require("config.utils").ts.find_node_ancestor(
          { "attribute_name", "directive_argument", "directive_name" },
          current_node
        )

        if html_attr_node then
          return '={""}<left><left>'
        else
          return "="
        end
      end, { expr = true, buffer = bufnr })
    end,
  },
  html = {
    opt = {
      commentstring = [[<!-- %s -->]],
    },
    callback = function(bufnr, args)
      vim.bo[bufnr].commentstring = [[<!-- %s -->]]

      -- Inside an attribute: <button type| pressing = -> <button type="|"
      vim.keymap.set("i", "=", function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local left_of_cursor_range = { cursor[1] - 1, cursor[2] - 1 }

        local current_node = vim.treesitter.get_node({ ignore_injections = false, pos = left_of_cursor_range })
        local html_attr_node = require("config.utils").ts.find_node_ancestor(
          { "attribute_name", "directive_argument", "directive_name" },
          current_node
        )

        if html_attr_node then
          return '=""<left>'
        else
          return "="
        end
      end, { expr = true, buffer = bufnr })
    end,
  },
  ghostty = {
    opt = {
      commentstring = [[# %s]],
    },
  },
  nix = {
    opt = {
      commentstring = "# %s",
      -- nil_ls = {},
    },
  },
  terminal = {
    opt = {
      relativenumber = false,
      number = false,
      signcolumn = "yes:1",
    },
  },
  gitconfig = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[# %s]],
    },
  },
  gitrebase = {
    callback = function(bufnr, args)
      vim.keymap.set(
        "n",
        "q",
        function() vim.cmd("cq!", { bang = true }) end,
        { buffer = bufnr, nowait = true, desc = "abort" }
      )
    end,
  },
  [{ "gitcommit", "NeogitCommitMessage" }] = {
    -- keys = {
    --   { "n", "q", function() vim.cmd("cq!") end, { nowait = true, buffer = true, desc = "abort", bang = true } },
    -- },
    bo = { bufhidden = "delete" },
    opt = {
      list = false,
      number = false,
      relativenumber = false,
      cursorline = false,
      spell = true,
      spelllang = "en_gb",
      colorcolumn = "50,72",
      conceallevel = 2,
      concealcursor = "nc",
    },
    callback = function()
      vim.keymap.set(
        "n",
        "q",
        function() vim.cmd("cq!", { bang = true }) end,
        { buffer = true, nowait = true, desc = "Abort" }
      )
      vim.fn.matchaddpos("DiagnosticVirtualTextError", { { 1, 50, 10000 } })
      if vim.api.nvim_get_current_line() == "" then vim.cmd.startinsert() end
    end,
  },
  fugitiveblame = {
    keys = {
      { "n", "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
    },
  },
  help = {
    keys = {
      { "n", "gd", "<C-]>" },
    },
    opt = {
      signcolumn = "no",
      splitbelow = true,
      number = true,
      relativenumber = true,
      list = false,
      textwidth = 80,
    },
    cmp = {
      sources = {
        { name = "git" },
        { name = "buffer" },
      },
    },
  },
  prompt = {
    opt = {
      signcolumn = "no",
      number = false,
      relativenumber = false,
      list = false,
    },
    callback = function(ctx)
      vim.pprint(ctx)
      print(vim.bo.buftype)
      print(vim.bo.filetype)
    end,
  },
  man = {
    keys = {
      { "n", "gd", "<C-]>" },
    },
    opt = {
      signcolumn = "no",
      splitbelow = true,
      number = true,
      relativenumber = true,
      list = false,
      textwidth = 80,
    },
  },
  oil = {
    keys = {},
    opt = {
      conceallevel = 3,
      concealcursor = "n",
      list = false,
      wrap = false,
      signcolumn = "no",
    },
    callback = function()
      local map = function(keys, func, desc) vim.keymap.set("n", keys, func, { buffer = 0, desc = "oil: " .. desc }) end

      map("q", "<cmd>q<cr>", "quit")
      map("<leader>ed", "<cmd>q<cr>", "quit")
      map("<BS>", function() require("oil").open() end, "goto parent dir")
    end,
  },
  [{ "javascript", "typescript" }] = {
    callback = function(bufnr)
      -- ABBREVIATIONS
      abbr("dbg", "console.debug", bufnr)
      abbr("cosnt", "const", bufnr)
      abbr("local", "const", bufnr)
      abbr("--", "//", bufnr)
      abbr("~=", "!==", bufnr)
      abbr("elseif", "else if", bufnr)
      abbr("()", "() =>", bufnr) -- quicker arrow function
    end,
  },
  lua = {
    abbr = {
      locla = "local",
      vll = "vim.log.levels",
    },
    keys = {
      { "n", "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>" },
    },
    opt = {
      comments = ":---,:--",
    },
    callback = function(bufnr)
      -- ABBREVIATIONS
      abbr("!=", "~=", bufnr)
    end,
  },
  mail = {
    callback = function(bufnr)
      vim.keymap.set("n", "j", "gj", { buffer = true })
      vim.keymap.set("n", "k", "gk", { buffer = true })

      vim.opt_local.textwidth = 80
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.spell = true
      vim.opt_local.spelllang = "en"
      vim.opt_local.formatoptions = "tcqwan"
      vim.opt_local.list = false
      vim.opt_local.synmaxcol = 0

      -- Start in insert mode after headers
      vim.cmd("normal! }o")
      vim.cmd.startinsert()
    end,
  },
  make = {
    opt = {
      expandtab = false,
    },
  },
  markdown = {
    abbr = {
      cab = [[Co-authored-by: First Last <email@example.com>]],
      cbt = "- [ ]",
      cb = "[ ]",
    },
    opt = {
      relativenumber = false,
      number = false,
      conceallevel = 2,
      shiftwidth = 2,
      tabstop = 2,
      softtabstop = 2,
      syntax = "OFF",
      -- formatoptions = "jqlnr",
      -- comments = "sb:- [x],mb:- [ ],b:-,b:*,b:>",
      linebreak = true,
      wrap = true,
      textwidth = 0,
      wrapmargin = 0,
      suffixesadd = ".md",
      spell = true,
      -- vim.o.textwidth = 0
      -- vim.o.wrapmargin = 0
      -- -- visual wrap (no real line cutting is made)
      -- vim.o.wrap = true
      -- vim.o.linebreak = true
    },
    cmp = {
      sources = {
        {
          name = "nvim_lsp",
          markdown_oxide = {
            keyword_pattern = [[\(\k\| \|\/\|#\|\^\)\+]],
          },
        },
        { name = "snippets" },
        { name = "git" },
        { name = "path" },
        { name = "spell" },
      },
    },
    callback = function(bufnr)
      local map = vim.keymap.set

      -- vim.schedule(function()
      --   map("i", "<CR>", function()
      --     local pair = require("nvim-autopairs").completion_confirm()
      --     if vim.bo.ft == "markdown" and pair == vim.api.nvim_replace_termcodes("<CR>", true, false, true) then
      --       vim.cmd.InsertNewBullet()
      --     else
      --       vim.api.nvim_feedkeys(pair, "n", false)
      --     end
      --   end, {
      --     buffer = bufnr,
      --   })
      -- end)

      ---sets `buffer`, `silent` and `nowait` to true
      ---@param mode string|string[]
      ---@param lhs string
      ---@param rhs string|function
      ---@param opts? { desc: string, remap: boolean }
      local function bmap(mode, lhs, rhs, opts)
        opts = vim.tbl_extend("force", { buffer = bufnr, silent = true, nowait = true }, opts or {})
        map(mode, lhs, rhs, opts)
      end

      if pcall(require, "mini.clue") then
        vim.b.miniclue_config = {
          clues = {
            { mode = "n", keys = "<localleader>m", desc = "+markdown" },
            { mode = "n", keys = "<C-g>", desc = "+markdown" },
            { mode = "i", keys = "<C-g>", desc = "+markdown" },
            { mode = "x", keys = "<C-g>", desc = "+markdown" },
          },
        }
      end

      bmap("v", "<localleader>mll", function()
        -- Copy what's currently in my clipboard to the register "a lamw25wmal
        vim.cmd("let @a = getreg('+')")
        -- delete selected text
        vim.cmd("normal d")
        -- Insert the following in insert mode
        vim.cmd("startinsert")
        vim.api.nvim_put({ "[]() " }, "c", true, true)
        -- Move to the left, paste, and then move to the right
        vim.cmd("normal F[pf(")
        -- Copy what's on the "a register back to the clipboard
        vim.cmd("call setreg('+', @a)")
        -- Paste what's on the clipboard
        vim.cmd("normal p")
        -- Leave me in normal mode or command mode
        vim.cmd("stopinsert")
        -- Leave me in insert mode to start typing
        -- vim.cmd("startinsert")
      end, { desc = "[P]Convert to link" })

      -- ctrl+g/ctrl+l: markdown link
      bmap("n", "<C-g><C-l>", "bi[<Esc>ea]()<Esc>hp", { desc = "[markdown]  link" })
      bmap("x", "<C-g><C-l>", "<Esc>`<i[<Esc>`>la]()<Esc>hp", { desc = "[markdown]  link" })
      bmap("i", "<C-g><C-l>", "[]()<Left><Left><Left>", { desc = "[markdown]  link" })

      -- ctrl+g/ctrl+b: bold
      bmap("n", "<C-g><C-b>", "bi**<Esc>ea**<Esc>", { desc = "[markdown]  bold" })
      bmap("i", "<C-g><C-b>", "****<Left><Left>", { desc = "[markdown]  bold" })
      bmap("x", "<C-g><C-b>", "<Esc>`<i**<Esc>`>lla**<Esc>", { desc = "[markdown]  bold" })

      -- ctrl+g/ctrl+i: italics
      bmap("n", "<C-g><C-i>", "bi*<Esc>ea*<Esc>", { desc = "[markdown]  italics" })
      bmap("i", "<C-g><C-i>", "**<Left>", { desc = "[markdown]  italics" })
      bmap("x", "<C-g><C-i>", "<Esc>`<i*<Esc>`>la*<Esc>", { desc = "[markdown]  italics" })

      -- ctrl+g ctrl+s: strike-through
      bmap("n", "<C-g><C-s>", "bi~~<Esc>ea~~<Esc>", { desc = "[markdown] 󰊁 strikethrough" })
      bmap("i", "<C-g><C-s>", "~~~~<Left><Left>", { desc = "[markdown] 󰊁 strikethrough" })
      bmap("x", "<C-g><C-s>", "<Esc>`<i~~<Esc>`>la~~<Esc>", { desc = "[markdown] 󰊁 strikethrough" })
    end,
  },
  ["neotest-summary"] = {
    opt = {
      wrap = false,
    },
  },
  norg = {
    opt = {
      comments = "n:-,n:( )",
      conceallevel = 2,
      indentkeys = "o,O,*<M-o>,*<M-O>,*<CR>",
      linebreak = true,
      wrap = true,
    },
  },
  org = {
    opt = {
      comments = "n:-,n:( )",
      conceallevel = 2,
      indentkeys = "o,O,*<M-o>,*<M-O>,*<CR>",
      linebreak = true,
      wrap = true,
    },
  },
  qf = {
    opt = {
      winfixheight = true,
      winfixwidth = true,
      relativenumber = false,
      number = false,
      buflisted = false,
      wrap = false,
    },
    -- callback = function()
    --   vim.cmd("wincmd J")
    --   vim.cmd([[
    --     " Autosize quickfix to match its minimum content
    --     " https://vim.fandom.com/wiki/Automatically_fitting_a_quickfix_window_height
    --     function! s:adjust_height(minheight, maxheight)
    --       exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
    --     endfunction
    --
    --     " force quickfix to open beneath all other splits
    --     call s:adjust_height(3, 10)
    --
    --     " REF: https://github.com/romainl/vim-qf/blob/2e385e6d157314cb7d0385f8da0e1594a06873c5/autoload/qf.vim#L22
    --   ]])
    --
    --   -- nnoremap("<C-n>", function()
    --   --   pcall(function()
    --   --     vim.cmd.lne({
    --   --       count = vim.v.count1,
    --   --     })
    --   --   end)
    --   -- end, { buffer = 0, label = "QF: next" })
    --   -- nnoremap("<C-p>", function()
    --   --   pcall(function()
    --   --     vim.cmd.lp({
    --   --       count = vim.v.count1,
    --   --     })
    --   --   end)
    --   -- end, { buffer = 0, label = "QF: previous" })
    --   -- vim.keymap.set(
    --   --   { "n", "x" },
    --   --   "<CR>",
    --   --   function()
    --   --     vim.cmd.ll({
    --   --       count = vim.api.nvim_win_get_cursor(0)[1],
    --   --     })
    --   --   end,
    --   --   {
    --   --     buffer = true,
    --   --   }
    --   -- )
    --
    --   local ok_bqf, bqf = pcall(require, "bqf")
    --   if not ok_bqf then
    --     return
    --   end
    --
    --   local fugitive_pv_timer
    --   local preview_fugitive = function(bufnr, qwinid, bufname)
    --     local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
    --     if fugitive_pv_timer and fugitive_pv_timer:get_due_in() > 0 then
    --       fugitive_pv_timer:stop()
    --       fugitive_pv_timer = nil
    --     end
    --     fugitive_pv_timer = vim.defer_fn(function()
    --       if not is_loaded then
    --         vim.api.nvim_buf_call(bufnr, function()
    --           vim.cmd(("do fugitive BufReadCmd %s"):format(bufname))
    --         end)
    --       end
    --       require("bqf.preview.handler").open(qwinid, nil, true)
    --       vim.api.nvim_set_option_value(
    --         "filetype",
    --         "git",
    --         { buf = require("bqf.preview.session").float_bufnr(), win = qwinid }
    --       )
    --     end, is_loaded and 0 or 60)
    --     return true
    --   end
    --
    --   bqf.setup({
    --     auto_enable = true,
    --     auto_resize_height = true,
    --     preview = {
    --       auto_preview = true,
    --       win_height = 15,
    --       win_vheight = 15,
    --       delay_syntax = 80,
    --       border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
    --       ---@diagnostic disable-next-line: unused-local
    --       should_preview_cb = function(bufnr, qwinid)
    --         local bufname = vim.api.nvim_buf_get_name(bufnr)
    --         local fsize = vim.fn.getfsize(bufname)
    --         if fsize > 100 * 1024 then
    --           -- skip file size greater than 100k
    --           return false
    --         elseif bufname:match("^fugitive://") then
    --           return preview_fugitive(bufnr, qwinid, bufname)
    --         end
    --
    --         return true
    --       end,
    --     },
    --     filter = {
    --       fzf = {
    --         extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
    --       },
    --     },
    --   })
    -- end,
  },
  lazy = {
    opt = {
      signcolumn = "no",
    },
  },
  query = {
    callback = function(bufnr)
      if vim.bo[bufnr].buftype == "nofile" then return end
      -- vim.lsp.start({
      --   name = "ts_query_ls",
      --   cmd = {
      --     vim.fs.joinpath(vim.env.HOME, "/code/ts_query_ls/target/release/ts_query_ls"),
      --   },
      --   root_dir = vim.fs.root(0, { "queries" }),
      --   settings = {
      --     parser_install_directories = {
      --       -- If using nvim-treesitter with lazy.nvim
      --       vim.fs.joinpath(vim.fn.stdpath("data"), "/lazy/nvim-treesitter/parser/"),
      --     },
      --     parser_aliases = {
      --       ecma = "javascript",
      --     },
      --     language_retrieval_patterns = {
      --       "languages/src/([^/]+)/[^/]+\\.scm$",
      --     },
      --   },
      -- })
    end,
  },
  [{ "sql", "dbee" }] = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[-- %s]],
    },
    cmp = {
      sources = {
        { name = "cmp-dbee" },
        { name = "vim-dadbod-completion" },
        { name = "buffer" },
      },
    },
  },
})

require("config.ftplugin").setup()
