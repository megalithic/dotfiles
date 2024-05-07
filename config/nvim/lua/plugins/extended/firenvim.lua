-- TODO:
-- https://github.com/jfpedroza/dotfiles/blob/master/nvim/after/plugin/firenvim.lua
-- https://github.com/stevearc/dotfiles/blob/master/.config/nvim/lua/plugins/firenvim.lua
local map = vim.keymap.set

return {
  "glacambre/firenvim",
  lazy = not vim.g.started_by_firenvim,
  cond = vim.g.started_by_firenvim,
  -- event = { "BufEnter", "BufReadPre", "UIEnter" },
  build = function() vim.fn["firenvim#install"](0) end,
  config = function()
    if not vim.g.started_by_firenvim then return end

    vim.g.firenvim_config = {
      globalSettings = {
        alt = "all",
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
        ["^https://docs\\.google\\.com/"] = {
          takeover = "never",
          priority = 1,
        },
        ["^https://meet\\.google\\.com/"] = {
          takeover = "never",
          priority = 1,
        },
        -- ["https?://gitter.im/"] = {
        --   takeover = "never",
        --   priority = 1,
        -- },
      },
      autocmds = {
        { "BufEnter", "github.com_*.txt", "setlocal filetype=markdown" },
        { "BufEnter", "leetcode.com_*.js", "setlocal filetype=typescript" },
        {
          "BufEnter",
          "gitter.im_*.txt",
          [[setlocal filetype=markdown | nnoremap <leader><CR> write<CR>:call firenvim#press_keys("<Lt>CR>")<CR>ggdGa]],
        },
      },
    }

    local function set_options(bufnr)
      bufnr = bufnr or 0
      -- disable headlines (until we update colours for forestbones)
      local ok_headlines, headlines = pcall(require, "headlines")
      if ok_headlines then
        headlines.setup({
          markdown = {
            headline_highlights = false,
            dash_highlight = false,
            codeblock_highlight = false,
          },
        })
      end

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
      vim.api.nvim_set_option("guifont", "JetBrainsMono Nerd Font:h22")
      vim.api.nvim_set_option("buftype", "firenvim")

      vim.diagnostic.disable(bufnr)
      vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = bufnr }))
    end

    local function set_lines(bufnr)
      vim.defer_fn(function()
        local buflines = vim.api.nvim_buf_line_count(bufnr)
        if vim.o.lines <= 15 or buflines < 30 then
          vim.o.lines = 30
        elseif buflines > 30 then
          vim.o.lines = buflines
        end
      end, 1)
    end

    local timer = nil
    local function throttle_write(delay, bufnr)
      if timer then timer:close() end
      timer = vim.loop.new_timer()
      timer:start(
        delay or 10, -- or 1000?
        0,
        vim.schedule_wrap(function()
          timer:close()
          timer = nil
          -- if vim.api.nvim_buf_get_option(bufnr, "modified") then
          if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
            vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
            set_lines(bufnr)
          end
        end)
      )
    end

    local function write(bufnr, params)
      local delay = vim.tbl_contains({ "FocusLost", "InsertLeave" }, params.event) and 10 or 1000
      throttle_write(delay, bufnr)
    end

    local function setup_write_autocmd(bufnr)
      -- We wait to call this function until the firenvim buffer is loaded
      local buf_group = vim.api.nvim_create_augroup("FireNvimWrite", {})
      vim.api.nvim_create_autocmd({ "FocusLost", "TextChanged", "TextChangedI", "InsertLeave" }, {
        buffer = bufnr,
        group = buf_group,
        nested = true,
        callback = function(params) write(bufnr, params) end,
      })
      -- vim.api.nvim_create_autocmd({ "FocusLost" }, {
      --   buffer = bufnr,
      --   group = buf_group,
      --   nested = true,
      --   callback = function(params) vim.cmd("wall | call firenvim#hide_frame() | call firenvim#focus_input()") end,
      -- })
    end

    local function on_bufenter(params)
      if params.file == "" then
        set_options()
      else
        local bufnr = params.buf or vim.api.nvim_get_current_buf() or 0
        local buflines = vim.api.nvim_buf_line_count(bufnr)
        set_lines(bufnr)

        if buflines == 1 then
          local function first_empty_line()
            -- local empty_line = nil
            local t = vim.api.nvim_buf_get_lines(0, 0, -1, true)
            for num, line in ipairs(t) do
              if line:match("^%s*$") then
                -- empty_line = num
                if num == 1 then vim.cmd([[startinsert!]]) end
                break
              end
            end

            -- return empty_line
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

        map("n", "<Esc>", "<cmd>wall | call firenvim#hide_frame() | call firenvim#press_keys('<LT>Esc>') | call firenvim#focus_page()<CR>")
        map("n", "<C-z>", "<cmd>wall | call firenvim#hide_frame() | call firenvim#focus_input()<CR>")
        map("n", "<C-c>", "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>")
        map("n", "<C-c>", "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>")
        map("n", "q", "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>")

        -- _G.mega.inoremap("<D-r>", function()
        --   -- local appName = vim.cmd([[!hs -c "hs.application.frontmostApplication():name()"]])
        --   -- print(appName)
        --
        --   local result = {}
        --   vim.fn.jobstart("hs -c 'hs.application.frontmostApplication():name()'", {
        --     stdout_buffered = true,
        --     on_stdout = function(_, data, _)
        --       for _, item in ipairs(data) do
        --         if item and item ~= "" then table.insert(result, item) end
        --       end
        --       print("stdout: " .. vim.inspect(result))
        --     end,
        --     on_exit = function(_, code, _)
        --       if code > 0 and not result or not result[1] then return end
        --       print("exited " .. code)
        --
        --       -- local parts = vim.split(result[1], "\t")
        --       -- if parts and #parts > 1 then
        --       --   local formatted = { behind = parts[1], ahead = parts[2] }
        --       --   vim.g.git_statusline_updates = formatted
        --       -- end
        --     end,
        --   })
        --
        --   -- print("after jobstart: " .. vim.inspect(result))
        --
        --   -- vim.fn.jobstart([[hs -c "hs.application.frontmostApplication()"]], {
        --   --   on_stdout = function(job_id, data, event)
        --   --     print("stdout")
        --   --     dd("stdout: " .. I({ job_id, data, event }))
        --   --   end,
        --   --   on_stderr = function(job_id, data, event)
        --   --     print("stderr")
        --   --     dd("stderr: " .. I({ job_id, data, event }))
        --   --   end,
        --   --   on_exit = function(job_id, data, event)
        --   --     print("stderr")
        --   --     dd("exit: " .. I({ job_id, data, event }))
        --   --   end,
        --   -- })
        --   -- hs.osascript.javascript([[Application(']] .. hs.application.frontmostApplication():name() .. [[').reload()]])
        -- end)

        -- disable cmp autocomplete
        require("cmp").setup.buffer({ enabled = false })

        bufnr = params.buf or vim.api.nvim_get_current_buf() or 0

        setup_write_autocmd(bufnr)
      end
    end

    require("mega.autocmds").augroup("Firenvim", {
      {
        event = { "UIEnter" },
        once = true,
        command = on_uienter,
      },
      {
        event = { "BufEnter" },
        pattern = "*",
        command = on_bufenter,
      },
      {
        event = { "FocusLost", "TextChanged", "TextChangedI", "InsertLeave" },
        buffer = vim.api.nvim_get_current_buf(),
        nested = true,
        command = function(params) write(params, vim.api.nvim_get_current_buf()) end,
      },
    })
  end,
}
