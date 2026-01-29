-- TODO:
-- https://github.com/jfpedroza/dotfiles/blob/master/nvim/after/plugin/firenvim.lua
-- https://github.com/stevearc/dotfiles/blob/master/.config/nvim/lua/plugins/firenvim.lua
-- https://github.com/letientai299/dotfiles/blob/master/vim/lua/firenvim_config.lua

return {
  "glacambre/firenvim",
  lazy = false,
  build = ":call firenvim#install(0)",
  config = function()
    if vim.g.started_by_firenvim then
      local map = vim.keymap.set

      vim.g.firenvim_config = {
        globalSettings = {
          alt = "all",
          ignoreKeys = {
            all = { "<C-->" },
            insert = { "<C-r>" },
            normal = {
              "<D-1>",
              "<D-2>",
              "<D-3>",
              "<D-4>",
              "<D-5>",
              "<D-6>",
              "<D-7>",
              "<D-8>",
              "<D-9>",
              "<D-0>",
              "<D-t>",
              "<D-r>",
            },
          },
        },
        localSettings = {
          [".*"] = {
            cmdline = "neovim", -- or firenvim
            content = "text",
            priority = 0,
            selector = "textarea:not([id='read-only-cursor-text-area'], [id='pull_request_review_body'])",
            takeover = "never",
            -- filename = "/tmp/{hostname}_{pathname%10}.{extension}",
          },
          ["^https?://github\\.com/"] = {
            takeover = "always",
            selector = "textarea:not([id='read-only-cursor-text-area'], [id='pull_request_review_body'])",
            priority = 1,
          },
          ["^https?://github\\.com/users/megalithic/projects"] = {
            takeover = "never",
            priority = 1,
          },
          ["^https?://stackoverflow\\.com/"] = {
            takeover = "always",
            priority = 1,
          },
          ["^https?://docs\\.google\\.com/"] = {
            takeover = "never",
            priority = 1,
          },
          ["^https?://meet\\.google\\.com/"] = {
            takeover = "never",
            priority = 1,
          },
        },
      }

      local function set_options(bufnr)
        bufnr = bufnr or 0

        vim.opt.shadafile = vim.fn.stdpath("state") .. "/shada/firenvim.shada"
        vim.opt.ruler = false
        vim.opt.wrap = true
        vim.opt.linebreak = true
        vim.opt.laststatus = 2
        vim.opt.cmdheight = 0
        vim.opt.showtabline = 0
        vim.opt.smoothscroll = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.statuscolumn = ""
        vim.opt_local.cursorlineopt = "screenline,number"
        vim.opt_local.cursorline = true
        vim.api.nvim_set_option_value("guifont", "JetBrainsMono Nerd Font:h22", {})
        vim.diagnostic.enable(false, { bufnr = bufnr })
        vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = bufnr }))
      end

      local timer = nil
      local function throttle_write(delay, bufnr)
        if timer then timer:close() end
        timer = vim.uv.new_timer()
        timer:start(
          delay or 10, -- or 1000?
          0,
          vim.schedule_wrap(function()
            timer:close()
            timer = nil
            -- if vim.api.nvim_buf_get_option(bufnr, "modified") then
            if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
              vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
            end
          end)
        )
      end

      local function write(bufnr, params)
        local delay = vim.tbl_contains({ "FocusLost", "InsertLeave" }, params.event) and 10 or 1000
        throttle_write(delay, bufnr)
      end

      local function setup_write_autocmd(bufnr)
        local buf_group = vim.api.nvim_create_augroup("FireNvimWrite", {})
        vim.api.nvim_create_autocmd({ "FocusLost", "TextChanged", "TextChangedI", "InsertLeave" }, {
          buffer = bufnr,
          group = buf_group,
          nested = true,
          callback = function(params) write(bufnr, params) end,
        })
      end

      local function on_bufenter(params)
        if params.file == "" then
          set_options()
        else
          local bufnr = params.buf or vim.api.nvim_get_current_buf() or 0
          local buflines = vim.api.nvim_buf_line_count(bufnr)

          if buflines == 1 then
            local function first_empty_line()
              local t = vim.api.nvim_buf_get_lines(0, 0, -1, true)
              for num, line in ipairs(t) do
                if line:match("^%s*$") then
                  if num == 1 then vim.cmd([[startinsert!]]) end
                  break
                end
              end
            end

            if true then first_empty_line() end
          end

          -- We wait to call this function until the firenvim buffer is loaded
          setup_write_autocmd(bufnr)
          set_options(bufnr)
        end
      end

      local function on_uienter(params)
        local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
        if client ~= nil and client.name == "Firenvim" then
          local bufnr = params.buf or vim.api.nvim_get_current_buf() or 0
          set_options(bufnr)

          vim.cmd([[
          tmap <D-v> <C-w>"+
          nnoremap <D-v> "+p
          vnoremap <D-v> "+p
          inoremap <D-v> <C-R><C-O>+
          cnoremap <D-v> <C-R><C-O>+
          inoremap <D-r> <nop>
        ]])

          vim.api.nvim_set_keymap("", "<D-c>", '"+y', { noremap = true, silent = true }) -- Copy
          vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
          vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
          vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
          vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

          -- Make navigating long lines easier in the tight view
          vim.api.nvim_set_keymap("n", "j", "gj", { noremap = true, silent = true })
          vim.api.nvim_set_keymap("n", "k", "gk", { noremap = true, silent = true })

          -- disable various UI elements to have more text lines.
          vim.o.showtabline = 0
          vim.o.showmode = false
          vim.o.signcolumn = "no"
          vim.o.showcmd = false
          vim.o.linespace = -2
          vim.o.laststatus = 0
          vim.o.cmdheight = 0
          -- vim.cmd("colo carbonfox")

          vim.fn.timer_start(100, function()
            if vim.o.lines < 20 then vim.o.lines = 20 end
            -- if vim.o.columns < 120 then vim.o.columns = 120 end
          end)

          map(
            "n",
            "<Esc>",
            "<cmd>wall | call firenvim#hide_frame() | call firenvim#press_keys('<LT>Esc>') | call firenvim#focus_page()<CR>"
          )
          map("n", "<C-z>", "<cmd>wall | call firenvim#hide_frame() | call firenvim#focus_input()<CR>")
          map("n", "<C-c>", "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>")
          map("n", "<C-c>", "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>")
          map("n", "q", "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>")

          bufnr = params.buf or vim.api.nvim_get_current_buf() or 0

          setup_write_autocmd(bufnr)
        end
      end

      local augroup = vim.api.nvim_create_augroup("Firenvim", { clear = true })
      vim.api.nvim_create_autocmd("UIEnter", {
        group = augroup,
        callback = on_uienter,
      })
      vim.api.nvim_create_autocmd({ "BufEnter", "WinResized" }, {
        group = augroup,
        pattern = "*",
        callback = on_bufenter,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        pattern = "github.com_*.txt",
        callback = function() vim.bo.filetype = "markdown" end,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup,
        pattern = "leetcode.com_*.js",
        callback = function() vim.bo.filetype = "typescript" end,
      })
    end
  end,
}
