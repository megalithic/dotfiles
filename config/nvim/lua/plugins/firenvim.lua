-- Firenvim: embed neovim in browser textareas
-- https://github.com/glacambre/firenvim

return {
  "glacambre/firenvim",
  lazy = false,
  build = ":call firenvim#install(0)",
  config = function()
    if not vim.g.started_by_firenvim then return end

    vim.g.firenvim_config = {
      globalSettings = {
        alt = "all",
        cmdlineTimeout = 3000,
        ignoreKeys = {
          all = { "<C-->" },
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
        [".*"] = { cmdline = "neovim", content = "text", priority = 0, selector = "textarea", takeover = "never" },

        -- GitHub: exclude PR review modal (causes flicker/lockup), search inputs
        ["^https?://github\\.com/"] = {
          takeover = "always",
          priority = 1,
          selector = "textarea:not([id='read-only-cursor-text-area'], [id='pull_request_review_body'], [name='pull_request_review[body]'], [aria-label*='pull request'], [placeholder*='Search'], [placeholder*='Filter'], [placeholder*='Go to file'])",
        },
        ["^https?://github\\.com/.*/projects"] = { takeover = "never", priority = 2 },

        ["^https?://stackoverflow\\.com/"] = { takeover = "always", priority = 1 },
        ["^https?://.*\\.stackexchange\\.com/"] = { takeover = "always", priority = 1 },

        -- Blocked
        ["^https?://docs\\.google\\.com/"] = { takeover = "never", priority = 1 },
        ["^https?://meet\\.google\\.com/"] = { takeover = "never", priority = 1 },
        ["^https?://mail\\.google\\.com/"] = { takeover = "never", priority = 1 },
        ["^https?://.*\\.slack\\.com/"] = { takeover = "never", priority = 1 },
        ["^https?://discord\\.com/"] = { takeover = "never", priority = 1 },
        ["^https?://.*\\.notion\\.so/"] = { takeover = "never", priority = 1 },
        ["^https?://.*\\.figma\\.com/"] = { takeover = "never", priority = 1 },
        ["^https?://linear\\.app/"] = { takeover = "never", priority = 1 },
      },
    }

    local timer = nil
    local function throttle_write(delay, bufnr)
      if timer then timer:close() end
      timer = vim.uv.new_timer()
      timer:start(
        delay,
        0,
        vim.schedule_wrap(function()
          if timer then
            timer:close()
            timer = nil
          end
          if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
            vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
          end
        end)
      )
    end

    local function setup_buf(bufnr)
      vim.opt_local.signcolumn = "no"
      vim.opt_local.statuscolumn = "%l "
      vim.opt_local.relativenumber = false
      vim.opt_local.number = true
      vim.opt_local.cursorline = true
      vim.opt_local.cursorlineopt = "screenline,number"
      vim.diagnostic.enable(false, { bufnr = bufnr })
      pcall(vim.lsp.stop_client, vim.lsp.get_clients({ bufnr = bufnr }))

      local grp = vim.api.nvim_create_augroup("FireNvimBuf_" .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "FocusLost", "TextChanged", "TextChangedI", "InsertLeave" }, {
        buffer = bufnr,
        group = grp,
        callback = function(e)
          throttle_write(e.event == "TextChanged" or e.event == "TextChangedI" and 1000 or 10, bufnr)
        end,
      })
    end

    local aug = vim.api.nvim_create_augroup("Firenvim", { clear = true })

    vim.api.nvim_create_autocmd("UIEnter", {
      group = aug,
      callback = function()
        local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
        if not client or client.name ~= "Firenvim" then return end

        vim.o.guifont = "JetBrainsMono Nerd Font:h22"
        vim.o.laststatus, vim.o.cmdheight, vim.o.showtabline = 0, 0, 0
        vim.o.showmode, vim.o.showcmd, vim.o.ruler = false, false, false
        vim.o.wrap, vim.o.linebreak, vim.o.linespace = true, true, -2
        vim.o.shadafile = vim.fn.stdpath("state") .. "/shada/firenvim.shada"
        vim.g.disable_autoformat = true
        vim.o.cmdheight = 1

        vim.defer_fn(function()
          if vim.o.lines < 15 then vim.o.lines = 15 end
        end, 100)

        -- macOS paste
        vim.cmd([[
          nnoremap <D-v> "+p| vnoremap <D-v> "+p| inoremap <D-v> <C-R><C-O>+| cnoremap <D-v> <C-R><C-O>+
          noremap <D-c> "+y
        ]])

        -- Wrapped line navigation
        vim.keymap.set("n", "j", "gj", { silent = true })
        vim.keymap.set("n", "k", "gk", { silent = true })

        -- Hide/focus
        vim.keymap.set("n", "<Esc>", function()
          vim.cmd("silent! wall")
          vim.fn["firenvim#hide_frame"]()
          vim.fn["firenvim#press_keys"]("<Esc>")
          vim.fn["firenvim#focus_page"]()
        end)
        vim.keymap.set("n", "<C-z>", function()
          vim.cmd("silent! wall")
          vim.fn["firenvim#hide_frame"]()
          vim.fn["firenvim#focus_input"]()
        end)
        vim.keymap.set("n", "q", function()
          vim.fn["firenvim#hide_frame"]()
          vim.fn["firenvim#focus_page"]()
        end)
        vim.keymap.set("n", "ZZ", function()
          vim.cmd("silent! wall")
          vim.fn["firenvim#hide_frame"]()
        end)

        setup_buf(vim.api.nvim_get_current_buf())
      end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      callback = function(e)
        if e.file ~= "" then setup_buf(e.buf) end
        local lines = vim.api.nvim_buf_get_lines(e.buf, 0, -1, false)
        if #lines <= 1 and (lines[1] or "") == "" then vim.defer_fn(function() vim.cmd("startinsert!") end, 50) end
      end,
    })

    -- Filetypes
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      pattern = { "github.com_*.txt", "gitlab.com_*.txt", "stackoverflow.com_*.txt" },
      callback = function() vim.bo.filetype = "markdown" end,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      pattern = "leetcode.com_*.js",
      callback = function() vim.bo.filetype = "javascript" end,
    })

    -- Auto-resize
    local resize_timer
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = aug,
      callback = function()
        if resize_timer then return end
        resize_timer = vim.defer_fn(function()
          resize_timer = nil
          local target = math.max(math.min(vim.api.nvim_buf_line_count(0) + 3, 30), 10)
          if vim.o.lines ~= target then vim.o.lines = target end
        end, 300)
      end,
    })
  end,
}
