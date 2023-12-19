-- REFs:
-- * https://jdhao.github.io/2019/01/15/markdown_edit_preview_nvim/
-- * https://github.com/dkarter/bullets.vim
-- * https://github.com/mnarrell/dotfiles/blob/main/nvim/lua/ftplugin/markdown.lua
-- * https://vim.works/2019/03/16/using-markdown-in-vim/

-- " source: https://gist.github.com/huytd/668fc018b019fbc49fa1c09101363397
-- " based on: https://www.reddit.com/r/vim/comments/h8pgor/til_conceal_in_vim/
-- " youtube video: https://youtu.be/UuHJloiDErM?t=793

if not vim.g.started_by_firenvim then vim.opt_local.textwidth = 80 end

vim.cmd([[autocmd FileType markdown nnoremap gO <cmd>Toc<cr>]])

-- vim.o.equalprg = [[prettier --stdin-filepath '%:p']]
-- vim.o.makeprg = [[open %]]

-- -- match and highlight hyperlinks
vim.fn.matchadd("matchURL", [[http[s]\?:\/\/[[:alnum:]%\/_#.-]*]])
vim.cmd(string.format("hi matchURL guifg=%s", require("mega.lush_theme.colors").bright_blue))
vim.cmd([[syn region markdownWikiLink matchgroup=markdownLinkDelimiter start="\[\[\w\+|" end="\]\]"]])

if vim.g.is_tmux_popup then
  -- ## used with markdown related tmux popups (through nvim)
  vim.opt_local.signcolumn = "no"
  vim.opt_local.cursorline = false
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false

  vim.opt.laststatus = 1
  vim.opt.cmdheight = 0
  vim.api.nvim_set_option_value(
    "winhl",
    table.concat({
      "Normal:TmuxPopupNormal",
      "FloatBorder:TmuxPopupNormal",
      "MsgArea:TmuxPopupNormal",
      "ModeMsg:TmuxPopupNormal",
      "NonText:TmuxPopupNormal",
    }, ","),
    { win = 0 }
  )

  vim.cmd("hi MsgArea guibg=#3d494f")
end

mega.iabbrev("-cc", "- [ ]", { "markdown" })
mega.iabbrev("cc", "[ ]", { "markdown" })
mega.iabbrev("cb", "[ ]", { "markdown" })
vim.cmd.iabbrev([[<expr> mdate "### ".strftime("%Y-%m-%d %H:%M:%S")]])
vim.cmd.iabbrev("<buffer>", "zTODO", "<span style=\"color:red\">TODO:</span><Esc>F<i")

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

        mega.nnoremap("<leader>nr", "<Cmd>ZkRecents<CR>", desc("zk: find recent notes"))

        mega.nnoremap("<leader>gr", "<cmd>ZkMatch<CR>", desc("zk: search notes matching under cursor"))
        mega.map({ "v", "x" }, "<leader>gr", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))

        mega.nnoremap("gn", "<cmd>ZkMatch<CR>", desc("zk: search notes matching under cursor"))
        mega.xnoremap("gm", "<esc><cmd>'<,'>ZkMatch<cr>", desc("zk: find notes in selection"))
        mega.nnoremap("gr", "<cmd>ZkMatch<CR>", desc("zk: search notes matching under cursor"))
        mega.map({ "v", "x" }, "gr", ":'<,'>ZkMatch<CR>", desc("zk: search notes matching selection"))

        mega.nnoremap("gl", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
        mega.nnoremap("[[", "<Cmd>ZkInsertLink<CR>", desc("zk: insert link"))
        mega.vnoremap("gl", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
        mega.vnoremap("[[", ":'<,'>ZkInsertLinkAtSelection<CR>", desc("zk: insert link (selected)"))
        mega.vnoremap(
          "gL",
          ":'<,'>ZkInsertLinkAtSelection {match = true}<CR>",
          desc("zk: insert link (search selected)")
        )
        mega.nnoremap(
          "<leader>nn",
          "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>",
          desc("zk: new note (with title)")
        )
        mega.nnoremap("gn", "<Cmd>ZkNew { title = vim.fn.input('title: ') }<CR>", desc("zk: new note (input title)"))

        mega.map(
          { "v", "x" },
          "<leader>nn",
          ":'<,'>ZkNewFromContentSelection { title = vim.fn.input('Title: ') }<CR>",
          desc("zk: new note from selection")
        )
        mega.map(
          { "v", "x" },
          "gn",
          ":'<,'>ZkNewFromContentSelection { title = vim.fn.input('Title: ') }<CR>",
          desc("zk: new note from selection")
        )
        mega.map(
          { "v", "x" },
          "<leader>nN",
          ":'<,'>ZkNewFromTitleSelection<CR>",
          desc("zk: new note title from selection")
        )
        mega.map({ "v", "x" }, "gN", ":'<,'>ZkNewFromTitleSelection<CR>", desc("zk: new note title from selection"))
      end
    end,
  },
})
