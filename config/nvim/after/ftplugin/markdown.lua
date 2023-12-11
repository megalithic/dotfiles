-- REFs:
-- * https://jdhao.github.io/2019/01/15/markdown_edit_preview_nvim/
-- * https://github.com/dkarter/bullets.vim
-- * https://github.com/mnarrell/dotfiles/blob/main/nvim/lua/ftplugin/markdown.lua
-- * https://vim.works/2019/03/16/using-markdown-in-vim/

-- " source: https://gist.github.com/huytd/668fc018b019fbc49fa1c09101363397
-- " based on: https://www.reddit.com/r/vim/comments/h8pgor/til_conceal_in_vim/
-- " youtube video: https://youtu.be/UuHJloiDErM?t=793

vim.opt_local.textwidth = 80
vim.cmd([[autocmd FileType markdown nnoremap gO <cmd>Toc<cr>]])

-- vim.o.equalprg = [[prettier --stdin-filepath '%:p']]
-- vim.o.makeprg = [[open %]]

vim.cmd([[iabbrev <expr> mdate "### ".strftime("%Y-%m-%d %H:%M:%S")]])
vim.cmd.iabbrev("<buffer>", "zTODO", "<span style=\"color:red\">TODO:</span><Esc>F<i")

-- quick section generators

-- {
--   "gaoDean/autolist.nvim",
--   ft = {
--     "org",
--     "neorg",
--     "plaintext",
--     "markdown",
--     "gitcommit",
--     "NeogitCommitMessage",
--     "COMMIT_EDITMSG",
--     "NEOGIT_COMMIT_EDITMSG",
--   },
--   config = function()
--     -- local al = require("autolist")
--     -- al.setup()
--     -- al.create_mapping_hook("i", "<CR>", al.new)
--     -- al.create_mapping_hook("i", "<Tab>", al.indent)
--     -- al.create_mapping_hook("i", "<S-Tab>", al.indent, "<C-d>")
--     -- al.create_mapping_hook("n", "o", al.new)
--     -- al.create_mapping_hook("n", "O", al.new_before)
--
--     require("autolist").setup()
--
--     vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
--     vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
--     -- vim.keymap.set("i", "<c-t>", "<c-t><cmd>AutolistRecalculate<cr>") -- an example of using <c-t> to indent
--     vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
--     vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
--     vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
--     vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
--     vim.keymap.set("n", "<C-r>", "<cmd>AutolistRecalculate<cr>")
--
--     -- cycle list types with dot-repeat
--     vim.keymap.set("n", "<localleader>cn", require("autolist").cycle_next_dr, { expr = true })
--     vim.keymap.set("n", "<localleader>cp", require("autolist").cycle_prev_dr, { expr = true })
--     -- if you don't want dot-repeat
--     -- vim.keymap.set("n", "<leader>cn", "<cmd>AutolistCycleNext<cr>")
--     -- vim.keymap.set("n", "<leader>cp", "<cmd>AutolistCycleNext<cr>")
--
--     -- functions to recalculate list on edit
--     vim.keymap.set("n", ">>", ">><cmd>AutolistRecalculate<cr>")
--     vim.keymap.set("n", "<<", "<<<cmd>AutolistRecalculate<cr>")
--     vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
--     vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")
--
--     mega.iabbrev("-cc", "- [ ]")
--     mega.iabbrev("cc", "[ ]")
--     mega.iabbrev("cb", "[ ]")
--   end,
-- },

-- TODO: convert these to vim.opt and vim.opt_local
-- vim.cmd([[
--   setlocal wrap
--   setlocal spell
--   setlocal nolist
--   setlocal foldexpr=markdown#FoldExpression(v:lnum)
--   setlocal foldmethod=expr
--   setlocal formatoptions+=t
--   setlocal linebreak
--   setlocal textwidth=0
--   setlocal autoindent tabstop=2 shiftwidth=2 formatoptions-=t comments=fb:>,fb:*,fb:+,fb:-
--   setlocal conceallevel=2
--   ]])

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

-- vim.g.markdown_enable_conceal = 1
-- vim.g.vim_markdown_folding_level = 10
-- vim.g.vim_markdown_folding_disabled = 1
-- vim.g.vim_markdown_conceal = 2
-- vim.g.vim_markdown_conceal_code_blocks = 0
-- vim.g.vim_markdown_folding_style_pythonic = 1
-- vim.g.vim_markdown_override_foldtext = 0
-- vim.g.vim_markdown_follow_anchor = 1
-- vim.g.vim_markdown_frontmatter = 1 -- for YAML format
-- vim.g.vim_markdown_toml_frontmatter = 1 -- for TOML format
-- vim.g.vim_markdown_json_frontmatter = 1 -- for JSON format
-- vim.g.vim_markdown_new_list_item_indent = 2
-- vim.g.vim_markdown_auto_insert_bullets = 0
-- vim.g.vim_markdown_no_extensions_in_markdown = 1
-- vim.g.vim_markdown_math = 1
-- vim.g.vim_markdown_strikethrough = 1
--
-- -- ## ixru/nvim-markdown
-- vim.g.vim_markdown_no_default_key_mappings = 1
-- vim.cmd([[map <Plug> <Plug>Markdown_FollowLink]])
--
-- -- ## iamcco/markdown-preview.nvim
-- vim.g.mkdp_auto_start = 0
-- vim.g.mkdp_auto_close = 1
--
-- -- match and highlight hyperlinks
vim.fn.matchadd("matchURL", [[http[s]\?:\/\/[[:alnum:]%\/_#.-]*]])
vim.cmd(string.format("hi matchURL guifg=%s", require("mega.lush_theme.colors").bright_blue))
vim.cmd([[syn region markdownWikiLink matchgroup=markdownLinkDelimiter start="\[\[\w\+|" end="\]\]"]])

mega.iabbrev("-cc", "- [ ]", "markdown")
mega.iabbrev("cc", "[ ]", "markdown")
mega.iabbrev("cb", "[ ]", "markdown")

if vim.g.is_tmux_popup then
  -- ## used with markdown related tmux popups (through nvim)
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

  -- local ok_headlines, headlines = pcall(require, "headlines")
  -- if ok_headlines then
  --   headlines.setup({
  --     markdown = {
  --       headline_highlights = false,
  --       dash_highlight = false,
  --       codeblock_highlight = false,
  --     },
  --   })
  -- end
end

mega.augroup("ZKMaps", {
  {
    event = { "BufEnter", "BufReadPre", "BufReadPost", "BufNewFile" },
    pattern = { string.format("%s/**/*.md", vim.env.ZK_NOTEBOOK_DIR) },
    command = function(args)
      if not vim.g.started_by_firenvim and require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
        local zk = require("zk")
        -- local util = require("zk.util")
        -- local api = require("zk.api")

        -- mega.iabbrev("ex:", "### elixir", "markdown")
        -- mega.iabbrev("mtg:", "### meeting", "markdown")
        -- mega.iabbrev("w:", "### work", "markdown")
        -- mega.iabbrev("pair:", "### pairing", "markdown")
        -- mega.iabbrev("dan:", "### 1:1 with dan", "markdown")
        -- mega.iabbrev("one:", "### 1:1 with dan", "markdown")
        -- mega.iabbrev("dots:", "### dotfiles", "markdown")

        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        -- HELPERS
        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        local picker_style = _G.picker[vim.g.picker]["ivy"]
        local desc = function(desc) return { desc = desc, noremap = true, silent = false, buffer = args.buf or 0 } end

        local function get_notes(...)
          if vim.g.picker == "fzf_lua" then return zk.command.get("ZkNotes")(...) end
          return require("telescope").extensions.zk.notes(picker_style(...))
        end
        local function get_tags(...)
          if vim.g.picker == "fzf_lua" then return zk.command.get("ZkTags")(...) end
          return require("telescope").extensions.zk.tags(picker_style(...))
        end

        -- Open the link under the caret.
        nnoremap("<CR>", "<cmd>lua vim.lsp.buf.definition()<CR>", desc("zk: open link under cursor"))

        -- Create a new note after asking for its title.
        -- This overrides the global `<space>zn` mapping to create the note in the same directory as the current buffer.
        nnoremap(
          "<localleader>zn",
          "<cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<cr>",
          desc("zk: new note in cwd")
        )
        -- Create a new note in the same directory as the current buffer, using the current selection for title.
        vnoremap(
          "<localleader>zn",
          ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<cr>",
          desc("zk: new note in cwd")
        )
        -- Create a new note in the same directory as the current buffer, using the current selection for note content and asking for its title.
        -- map("v", "<space>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", desc("zk: open link under cursor"))

        -- Open notes linking to the current buffer.
        nnoremap("<localleader>zb", "<cmd>ZkBacklinks<cr>", desc("zk: open back links for the current buffer"))
        -- Alternative for backlinks using pure LSP and showing the source context.
        --map('n', '<space>zb', '<cmd>lua vim.lsp.buf.references()<cr>', desc("zk: open link under cursor"))
        -- Open notes linked by the current buffer.
        nnoremap("<localleader>zl", "<cmd>ZkLinks<cr>", desc("zk: open notes linked by the current buffer"))

        -- Preview a linked note.
        nnoremap("K", "<cmd>lua vim.lsp.buf.hover()<cr>", desc("zk: preview the linked note"))

        -- Open the code actions for a visual selection.
        vnoremap(
          "<localleader>za",
          ":'<,'>lua vim.lsp.buf.code_action()<cr>",
          desc("zk: open the code actions for visual selection")
        )

        -- Insert a link from the note picker
        inoremap("[[", "<cmd>ZkInsertLink<cr>", desc("zk: insert link from the note picker"))

        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        -- MAPPINGS
        -- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
        mega.nnoremap("<leader>nf", function() get_notes({ sort = { "modified" } }) end, desc("zk: find notes"))
        mega.nnoremap(
          "<leader>nw",
          function() get_notes({ sort = { "modified" }, tags = { "tern OR work" } }, { title = "work notes" }) end,
          desc("zk: work notes")
        )
        mega.nnoremap(
          "<leader>nd",
          function() get_notes({ sort = { "modified" }, tags = { "daily" } }, { title = "daily notes" }) end,
          desc("zk: daily notes")
        )
        mega.nnoremap(
          "<leader>nl",
          function()
            get_notes({
              linkedBy = { vim.api.nvim_buf_get_name(0) },
            })
          end,
          desc("zk: links")
        )
        mega.nnoremap(
          "<leader>nb",
          function()
            get_notes({
              linkedTo = { vim.api.nvim_buf_get_name(0) },
            })
          end,
          desc("zk: backlinks")
        )
        mega.nnoremap("<leader>nt", function() get_tags() end, desc("zk: tags"))
        mega.nnoremap("gt", function() get_tags() end, desc("zk: tags"))
        -- FIXME: not quite working
        mega.nnoremap(
          "<leader>na",
          function()
            get_notes({
              match = {},
            }, { title = "live grep notes" })
          end,
          { desc = "zk: live grep notes" }
        )

        mega.xnoremap("gm", "<esc><cmd>'<,'>ZkMatch<cr>", desc("zk: find notes in selection"))
        mega.nnoremap("gm", "<esc><cmd>ZkMatch<cr>", desc("zk: find notes under cursor"))
        mega.nnoremap("<leader>nr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))
        mega.vnoremap("<leader>gr", "<cmd>ZkMatch<CR>", desc("zk: search notes matching under cursor"))
        mega.vnoremap("<leader>gr", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
        mega.map({ "v", "x" }, "<leader>gr", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))
        mega.nnoremap("gi", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
        mega.vnoremap("gi", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
        mega.vnoremap(
          "gI",
          ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>",
          desc("zk: insert link (search selected)")
        )
        mega.nnoremap("<leader>nn", "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>", desc("zk: new note"))

        mega.map(
          { "v", "x" },
          "<leader>nn",
          ":'<,'>ZkNewFromContentSelection { title = vim.fn.input('Title: ') }<CR>",
          desc("zk: new note from selection")
        )
        mega.map(
          { "v", "x" },
          "<leader>nN",
          ":'<,'>ZkNewFromTitleSelection<CR>",
          desc("zk: new note title from selection")
        )
      end
    end,
  },
})
