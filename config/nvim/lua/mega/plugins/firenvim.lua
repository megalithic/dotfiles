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
        -- filename = "/tmp/{hostname}_{pathname%10}.{extension}",
      },
      ["https?://github.com/"] = {
        takeover = "always",
        priority = 1,
      },
      ["https?://stackoverflow.com/"] = {
        takeover = "always",
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
        --[[
        normal! i
        inoremap <CR> <Esc>:w<CR>:call firenvim#press_keys("<LT>CR>")<CR>ggdGa
        inoremap <s-CR> <CR>
        --]]
      },
    },
  }

  local firenvim_onload = function(evt)
    vim.notify(fmt("firenvim_onload: %s", evt.event))
    vim.defer_fn(function()
      vim.notify("firenvim_onload_defer_fn")
      vim.cmd.colorscheme("forestbones")

      do
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
      end

      do
        local ok, cmp = mega.require("cmp")
        if ok then cmp.setup({ autocomplete = false }) end
      end

      vim.opt.wrap = true
      vim.opt.linebreak = true
      vim.opt.laststatus = 0
      vim.opt.showtabline = 0
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn = "no"
      vim.opt_local.cursorlineopt = "screenline,number"
      vim.opt_local.cursorline = true

      require("mega.globals").nnoremap(
        "<Esc><Esc>",
        "<cmd>wall | call firenvim#hide_frame() | call firenvim#press_keys('<LT>Esc>') | call firenvim#focus_page()<CR>"
      )
      require("mega.globals").inoremap(
        "<C-c>",
        "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>"
      )
      require("mega.globals").nnoremap(
        "<C-c>",
        "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>"
      )
      require("mega.globals").nnoremap(
        "<C-z>",
        "<cmd>wall | call firenvim#hide_frame() | call firenvim#focus_input()<CR>"
      )
      require("mega.globals").nnoremap(
        "q",
        "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>"
      )
      -- vim.defer_fn(function() vim.opt.guifont = "FiraCode Nerd Font Mono:h22" end, 1000)
      vim.opt.guifont = "JetBrainsMono_Nerd_Font_Mono:h22"
      -- if vim.o.lines < 30 then vim.o.lines = 30 end
      vim.cmd([[exec "norm gg"]]) -- test: 聆

      -- print(string.format("lines: %d", vim.api.nvim_buf_line_count(0)))
      -- if vim.api.nvim_buf_line_count(0) == 1 and vim.fn.prevnonblank(".") ~= vim.fn.line(".") then
      --   vim.cmd([[startinsert]])
      -- end
    end, 750)
  end

  function IsFirenvimActive(event)
    if vim.g.debug_enabled then print("IsFirenvimActive, event: ", vim.inspect(event)) end
    if vim.fn.exists("*nvim_get_chan_info") == 0 then return 0 end
    local ui = vim.api.nvim_get_chan_info(event.chan)
    if vim.g.debug_enabled then print("IsFirenvimActive, ui: ", vim.inspect(ui)) end
    local is_firenvim_active_in_browser = (ui["client"] ~= nil and ui["client"]["name"] ~= nil)
    if vim.g.enable_vim_debug then print("is_firenvim_active_in_browser: ", is_firenvim_active_in_browser) end
    return is_firenvim_active_in_browser
  end

  function OnUIEnter(event)
    if IsFirenvimActive(event) then firenvim_onload({ event = "UIEnter" }) end
  end
  vim.cmd([[autocmd UIEnter * :call luaeval('OnUIEnter(vim.fn.deepcopy(vim.v.event))')]])

  require("mega.globals").augroup("Firenvim", {
    {
      event = { "BufEnter" },
      command = function(evt) firenvim_onload(evt) end,
    },
  })
end