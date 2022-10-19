return function()
  if not vim.g.started_by_firenvim then return end

  vim.g.firenvim_config = {
    globalSettings = {
      alt = "all",
    },
    localSettings = {
      [".*"] = {
        cmdline = "neovim",
        content = "text",
        priority = 0,
        selector = "textarea",
        takeover = "never",
      },
      ["https?://github.com/"] = {
        takeover = "always",
        priority = 1,
      },
      ["https?://stackoverflow.com/"] = {
        takeover = "always",
        priority = 1,
      },
      ["https?://gitter.im/"] = {
        takeover = "always",
        priority = 1,
      },
      ["https?://linear.app/"] = {
        takeover = "always",
        selector = ".editor.ProseMirror",
        priority = 1,
      },
    },
    autocmds = {
      { "BufEnter", "github.com_*.txt", "setlocal filetype=markdown" },
      { "BufEnter", "leetcode.com_*.js", "setlocal filetype=typescript" },
    },
  }

  require("mega.globals").augroup("FireNvim", {
    {
      event = { "BufEnter" },
      command = function()
        vim.cmd.colorscheme("forestbones")

        local ok, headlines = mega.require("headlines")
        if ok then
          headlines.setup({
            markdown = {
              headline_highlights = false,
              dash_highlight = false,
              codeblock_highlight = false,
            },
          })
        end

        vim.opt.wrap = true
        vim.opt.linebreak = true
        vim.opt.laststatus = 0
        vim.opt.showtabline = 0
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.cursorlineopt = "number"
        vim.opt_local.cursorline = true

        vim.cmd([[exec 'norm gg']]) -- test: 聆

        if vim.api.nvim_buf_line_count(0) <= 2 then
          -- if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then vim.cmd([[startinsert]]) end
          vim.cmd([[startinsert]])
        end

        require("mega.globals").nmap("<Esc><Esc>", vim.fn["firenvim#focus_page"])
        require("mega.globals").nmap("<C-Z>", vim.fn["firenvim#hide_frame"])

        -- vim.defer_fn(function() vim.opt.guifont = "JetBrainsMono_Nerd_Font_Mono:h22" end, 1000)
        vim.defer_fn(function() vim.cmd([[set guifont=JetBrainsMono\ Nerd\ Font\ Mono:h22]]) end, 1000)
      end,
    },
  })
end
