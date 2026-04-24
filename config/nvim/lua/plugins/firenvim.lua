-- Firenvim: embed neovim in browser textareas
-- https://github.com/glacambre/firenvim

-- Set config BEFORE plugin loads (required for firenvim#install to pick it up)
vim.g.firenvim_config = {
  globalSettings = {
    alt = "all",
    cmdlineTimeout = 3000,
    ignoreKeys = {
      all = { "<C-->" },
      normal = { "<D-1>", "<D-2>", "<D-3>", "<D-4>", "<D-5>", "<D-6>", "<D-7>", "<D-8>", "<D-9>", "<D-0>", "<D-t>", "<D-r>" },
    },
  },
  localSettings = {
    -- Default: never auto-takeover, manual Cmd+e only
    [".*"] = {
      cmdline = "neovim",
      content = "text",
      priority = 0,
      selector = "textarea",
      takeover = "never",
    },
    -- GitHub: completely disabled on PR pages (avoids hidden textarea errors)
    ["^https?://github\\.com/.*/pull/"] = { takeover = "never", priority = 1 },
    ["^https?://github\\.com/.*/projects"] = { takeover = "never", priority = 1 },
    -- Sites that work well with firenvim
    ["^https?://stackoverflow\\.com/"] = { takeover = "never", priority = 1, selector = "textarea" },
    ["^https?://.*\\.stackexchange\\.com/"] = { takeover = "never", priority = 1, selector = "textarea" },
    -- Blocked sites (complex editors, real-time apps)
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

return {
  "glacambre/firenvim",
  -- Only load the plugin when started by firenvim, but config above is always set
  lazy = not vim.g.started_by_firenvim,
  build = function()
    -- Ensure plugin runtime is loaded so autoload/firenvim.vim is sourced
    require("lazy").load({ plugins = { "firenvim" } })
    vim.fn["firenvim#install"](0)
  end,
  config = function()
    -- Only run setup when actually in firenvim
    if not vim.g.started_by_firenvim then
      return
    end

    -- Throttled write function
    local timer = nil
    local function throttle_write(delay, bufnr)
      if timer then
        timer:close()
      end
      timer = vim.uv.new_timer()
      timer:start(delay, 0, vim.schedule_wrap(function()
        if timer then
          timer:close()
          timer = nil
        end
        if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd("silent! write")
          end)
        end
      end))
    end

    -- Buffer-local setup
    local function setup_buf(bufnr)
      vim.opt_local.signcolumn = "no"
      vim.opt_local.statuscolumn = ""
      vim.opt_local.relativenumber = false
      vim.opt_local.number = false
      vim.opt_local.cursorline = true
      vim.opt_local.cursorlineopt = "screenline"

      -- Disable LSP and diagnostics for performance
      vim.diagnostic.enable(false, { bufnr = bufnr })
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        pcall(function() client:stop() end)
      end

      -- Auto-save on changes
      local grp = vim.api.nvim_create_augroup("FireNvimBuf_" .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "FocusLost", "TextChanged", "TextChangedI", "InsertLeave" }, {
        buffer = bufnr,
        group = grp,
        callback = function(e)
          local delay = (e.event == "TextChanged" or e.event == "TextChangedI") and 1000 or 10
          throttle_write(delay, bufnr)
        end,
      })
    end

    -- Main autocmd group
    local aug = vim.api.nvim_create_augroup("Firenvim", { clear = true })

    -- UI setup on firenvim start
    vim.api.nvim_create_autocmd("UIEnter", {
      group = aug,
      callback = function()
        local client = vim.api.nvim_get_chan_info(vim.v.event.chan).client
        if not client or client.name ~= "Firenvim" then
          return
        end

        -- UI options
        vim.o.guifont = "JetBrainsMono Nerd Font:h22"
        vim.o.laststatus = 0
        vim.o.cmdheight = 1
        vim.o.showtabline = 0
        vim.o.showmode = false
        vim.o.showcmd = false
        vim.o.ruler = false
        vim.o.wrap = true
        vim.o.linebreak = true
        vim.o.linespace = -2
        vim.o.shadafile = vim.fn.stdpath("state") .. "/shada/firenvim.shada"
        vim.g.disable_autoformat = true

        -- Minimum size
        vim.defer_fn(function()
          if vim.o.lines < 15 then
            vim.o.lines = 15
          end
        end, 100)

        -- macOS clipboard
        vim.cmd([[
          nnoremap <D-v> "+p
          vnoremap <D-v> "+p
          inoremap <D-v> <C-R><C-O>+
          cnoremap <D-v> <C-R><C-O>+
          noremap <D-c> "+y
        ]])

        -- Wrapped line navigation
        vim.keymap.set("n", "j", "gj", { silent = true })
        vim.keymap.set("n", "k", "gk", { silent = true })

        -- Exit keymaps
        vim.keymap.set("n", "<Esc>", function()
          vim.cmd("silent! wall")
          vim.fn["firenvim#hide_frame"]()
          vim.fn["firenvim#focus_input"]()
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

    -- Buffer enter setup
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      callback = function(e)
        if e.file ~= "" then
          setup_buf(e.buf)
        end
        -- Start insert if buffer is empty
        local first_line = vim.api.nvim_buf_get_lines(e.buf, 0, 1, false)[1] or ""
        if first_line:match("^%s*$") then
          vim.defer_fn(function()
            vim.cmd("startinsert!")
          end, 50)
        end
      end,
    })

    -- Filetypes
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      pattern = { "github.com_*.txt", "gitlab.com_*.txt", "stackoverflow.com_*.txt" },
      callback = function()
        vim.bo.filetype = "markdown"
      end,
    })
  end,
}
