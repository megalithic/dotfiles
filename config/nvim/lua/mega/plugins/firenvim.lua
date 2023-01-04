local M = {
  "glacambre/firenvim",
  lazy = false,
  build = function() vim.fn["firenvim#install"](0) end,
}

function M.init()
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
      ["https?://github.com/users/megalithic/projects"] = {
        takeover = "never",
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

  local function on_bufenter(evt)
    -- vim.opt.guifont = "JetBrainsMono_Nerd_Font_Mono:h22"
    vim.opt.guifont = "JetBrainsMono Nerd Font Mono:h22"

    -- P(fmt("lines: %s, win_height: %s", vim.o.lines, vim.api.nvim_win_get_height(vim.api.nvim_get_current_win())))

    local bufnr = evt.buf or 0
    local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    local buf_name = vim.api.nvim_buf_get_name(bufnr)

    -- start in insert mode if we're an empty buffer
    if buf_name ~= "" and _G.mega.tlen(buf_lines) <= 2 and buf_lines[1] == "" then
      vim.cmd([[startinsert]])
    else
      vim.cmd([[exec "norm gg"]])
    end

    -- expand the firenvim window larger than it should be, (if it's presently less than 25 lines)
    if vim.o.lines < 15 then vim.o.lines = 15 end
  end

  local function on_uienter(evt)
    vim.cmd.colorscheme("forestbones")

    -- disable headlines (until we update colours for forestbones)
    local ok_headlines, headlines = mega.require("headlines")
    if ok_headlines then
      headlines.setup({
        markdown = {
          headline_highlights = false,
          dash_highlight = false,
          codeblock_highlight = false,
        },
      })
    end

    require("autolist").setup({ normal_mappings = { invert = { "<c-c>" } } })

    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.laststatus = 0
    vim.opt.showtabline = 0
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.cursorlineopt = "screenline,number"
    vim.opt_local.cursorline = true

    vim.cmd([[
      tmap <D-v> <C-w>"+
      nnoremap <D-v> "+p
      vnoremap <D-v> "+p
      inoremap <D-v> <C-R><C-O>+
      cnoremap <D-v> <C-R><C-O>+
    ]])

    require("mega.globals").nnoremap(
      "<Esc>",
      "<cmd>wall | call firenvim#hide_frame() | call firenvim#press_keys('<LT>Esc>') | call firenvim#focus_page()<CR>"
    )
    require("mega.globals").nnoremap(
      "<C-z>",
      "<cmd>wall | call firenvim#hide_frame() | call firenvim#focus_input()<CR>"
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
      "q",
      "<cmd>call firenvim#hide_frame() | call firenvim#focus_page()<CR><Esc>norm! ggdGa<CR>"
    )

    -- disable cmp autocomplete
    require("cmp").setup({ autocomplete = false })
  end

  require("mega.globals").augroup("Firenvim", {
    {
      event = { "UIEnter" },
      once = true,
      command = function(evt) on_uienter(evt) end,
    },
    {
      event = { "BufEnter" },
      command = function(evt) on_bufenter(evt) end,
    },
  })
end

return M
