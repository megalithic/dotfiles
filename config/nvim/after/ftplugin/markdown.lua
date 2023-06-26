-- REFs:
-- * https://jdhao.github.io/2019/01/15/markdown_edit_preview_nvim/
-- * https://github.com/dkarter/bullets.vim
-- * https://github.com/mnarrell/dotfiles/blob/main/nvim/lua/ftplugin/markdown.lua
-- * https://vim.works/2019/03/16/using-markdown-in-vim/

-- " source: https://gist.github.com/huytd/668fc018b019fbc49fa1c09101363397
-- " based on: https://www.reddit.com/r/vim/comments/h8pgor/til_conceal_in_vim/
-- " youtube video: https://youtu.be/UuHJloiDErM?t=793
-- Custom conceal (does not work with existing syntax highlight plugin)

vim.cmd([[autocmd FileType markdown nnoremap gO <cmd>Toc<cr>]])

vim.o.equalprg = [[prettier --stdin-filepath '%:p']]
vim.o.makeprg = [[open %]]

vim.cmd([[iabbrev <expr> mdate "### ".strftime("%Y-%m-%d %H:%M:%S")]])
vim.cmd.iabbrev("<buffer>", "zTODO", "<span style=\"color:red\">TODO:</span><Esc>F<i")

-- TODO: convert these to vim.opt and vim.opt_local
vim.cmd([[
  setlocal wrap
  setlocal spell
  setlocal nolist
  setlocal foldexpr=markdown#FoldExpression(v:lnum)
  setlocal foldmethod=expr
  setlocal formatoptions+=t
  setlocal nolist

  setlocal linebreak
  setlocal textwidth=0
  setlocal autoindent tabstop=2 shiftwidth=2 formatoptions-=t comments=fb:>,fb:*,fb:+,fb:-
  setlocal conceallevel=2
  ]])

-- ## plasticboy/vim-markdown
-- vim.g.markdown_fenced_languages = {
--   "diff",
--   "javascript",
--   "js=javascript",
--   "json=javascript",
--   "typescript",
--   "css",
--   "scss",
--   "sass",
--   "ruby",
--   "erb=eruby",
--   "python",
--   "haml",
--   "html",
--   "bash=sh",
--   "zsh=sh",
--   "shell=sh",
--   "console=sh",
--   "sh",
--   "elm",
--   -- "elixir",
--   -- "eelixir",
--   "lua",
--   "vim",
--   "viml",
-- }

vim.g.markdown_enable_conceal = 1
vim.g.vim_markdown_folding_level = 10
vim.g.vim_markdown_folding_disabled = 1
vim.g.vim_markdown_conceal = 2
vim.g.vim_markdown_conceal_code_blocks = 0
vim.g.vim_markdown_folding_style_pythonic = 1
vim.g.vim_markdown_override_foldtext = 0
vim.g.vim_markdown_follow_anchor = 1
vim.g.vim_markdown_frontmatter = 1 -- for YAML format
vim.g.vim_markdown_toml_frontmatter = 1 -- for TOML format
vim.g.vim_markdown_json_frontmatter = 1 -- for JSON format
vim.g.vim_markdown_new_list_item_indent = 2
vim.g.vim_markdown_auto_insert_bullets = 0
vim.g.vim_markdown_no_extensions_in_markdown = 1
vim.g.vim_markdown_math = 1
vim.g.vim_markdown_strikethrough = 1

-- ## ixru/nvim-markdown
vim.g.vim_markdown_no_default_key_mappings = 1
vim.cmd([[map <Plug> <Plug>Markdown_FollowLink]])

-- ## iamcco/markdown-preview.nvim
vim.g.mkdp_auto_start = 0
vim.g.mkdp_auto_close = 1

-- ## used with my zk popups in tmux
if vim.env.TMUX_POPUP then
  vim.opt_local.signcolumn = "no"
  vim.opt_local.cursorline = false
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false

  vim.opt.laststatus = 1
  vim.opt.cmdheight = 0
  vim.api.nvim_win_set_option(
    0,
    "winhl",
    table.concat({
      "Normal:TmuxPopupNormal",
      "FloatBorder:TmuxPopupNormal",
      "MsgArea:TmuxPopupNormal",
      "ModeMsg:TmuxPopupNormal",
      "NonText:TmuxPopupNormal",
    }, ",")
  )

  vim.cmd("hi MsgArea guibg=#3d494f")
end

-- match and highlight hyperlinks
vim.fn.matchadd("matchURL", [[http[s]\?:\/\/[[:alnum:]%\/_#.-]*]])
vim.cmd(string.format("hi matchURL guifg=%s", require("mega.lush_theme.colors").bright_blue))

-- local cmp_ok, cmp = mega.require("nvim-cmp")
-- if cmp_ok then
--   if not vim.g.started_by_firenvim then
--     cmp.setup.filetype("markdown", {
--       sources = cmp.config.sources({
--         { name = "dictionary" },
--         { name = "spell" },
--         { name = "emoji" },
--       }, {
--         { name = "buffer" },
--       }),
--     })
--   else
--     cmp.setup.filetype("markdown", {
--       sources = cmp.config.sources({}),
--     })
--   end
-- end
--
-- local ms_ok, ms = mega.require("mini.surround")
-- if ms_ok then
--   vim.b.minisurround_config = {
--     custom_surroundings = {
--       l = {
--         output = function()
--           local clipboard = vim.fn.getreg("+"):gsub("\n", "")
--           return { left = "[", right = "](" .. clipboard .. ")" }
--         end,
--       },
--       L = {
--         output = function()
--           local link_name = ms.user_input("Enter the link name: ")
--           return {
--             left = "[" .. link_name .. "](",
--             right = ")",
--           }
--         end,
--       },
--       ["b"] = { -- Surround for bold
--         input = { "%*%*().-()%*%*" },
--         output = { left = "**", right = "**" },
--       },
--       ["i"] = { -- Surround for italics
--         input = { "%*().-()%*" },
--         output = { left = "*", right = "*" },
--       },
--     },
--   }
-- end
mega.augroup("ZKMaps", {
  {
    event = { "BufEnter", "BufReadPre", "BufReadPost", "BufNewFile" },
    pattern = { string.format("%s/**/*.md", vim.env.ZK_NOTEBOOK_DIR) },
    command = function()
      dd("presently in a zk file")
      if not vim.g.started_by_firenvim and require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
        local desc = function(desc) return { desc = desc, noremap = true, silent = false, buffer = 0 } end

        -- Open the link under the caret.
        nnoremap("<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", desc("zk: open link under cursor"))

        -- Create a new note after asking for its title.
        -- This overrides the global `<space>zn` mapping to create the note in the same directory as the current buffer.
        nnoremap(
          "<space>zn",
          "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
          desc("zk: new note in cwd")
        )
        -- Create a new note in the same directory as the current buffer, using the current selection for title.
        vnoremap(
          "<space>zn",
          ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",
          desc("zk: new note in cwd")
        )
        -- Create a new note in the same directory as the current buffer, using the current selection for note content and asking for its title.
        -- map("v", "<space>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", desc("zk: open link under cursor"))

        -- Open notes linking to the current buffer.
        nnoremap("<space>zb", "<Cmd>ZkBacklinks<CR>", desc("zk: open back links for the current buffer"))
        -- Alternative for backlinks using pure LSP and showing the source context.
        --map('n', '<space>zb', '<Cmd>lua vim.lsp.buf.references()<CR>', desc("zk: open link under cursor"))
        -- Open notes linked by the current buffer.
        nnoremap("<space>zl", "<Cmd>ZkLinks<CR>", desc("zk: open notes linked by the current buffer"))

        -- Preview a linked note.
        nnoremap("K", "<Cmd>lua vim.lsp.buf.hover()<CR>", desc("zk: preview the linked note"))

        -- Open the code actions for a visual selection.
        vnoremap(
          "<space>za",
          ":'<,'>lua vim.lsp.buf.code_action()<CR>",
          desc("zk: open the code actions for visual selection")
        )

        -- Insert a link from the note picker
        inoremap("[[", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link from the note picker"))
      end
    end,
  },
})

-- mega.conf("bullets.vim", function()
--   vim.g.bullets_enabled_file_types = {
--     "markdown",
--     "text",
--     "gitcommit",
--     "scratch",
--   }
--   vim.g.bullets_checkbox_markers = " ○◐✗"
--   vim.g.bullets_set_mappings = 0
--   -- vim.g.bullets_outline_levels = { "num" }

--   -- vim.cmd([[
--   --       " Disable default bullets.vim mappings, clashes with other mappings
--   --       let g:bullets_set_mappings = 0
--   --       " let g:bullets_checkbox_markers = '✗○◐●✓'
--   --       let g:bullets_checkbox_markers = ' .oOx'

--   --       " Add custom bullets mappings that don't clash with other mappings
--   --       function! InsertNewBullet()
--   --         InsertNewBullet
--   --         return ''
--   --       endfunction

--   --         " \ inoremap <buffer><expr> <cr> (pumvisible() ? '<C-y>' : '<C-]><C-R>=InsertNewBullet()<cr>')|
--   --       autocmd FileType markdown,text,gitcommit
--   --         \ nnoremap <silent><buffer> o :InsertNewBullet<cr>|
--   --         \ nnoremap cx :ToggleCheckbox<cr>
--   --         \ nmap <C-x> :ToggleCheckbox<cr>
--   --     ]])
-- end)
