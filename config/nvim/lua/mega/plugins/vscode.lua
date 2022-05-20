-- @HT: graciously thieved from https://github.com/echasnovski/nvim/blob/master/lua/ec/vscode.lua
return function()
  if vim.g.vscode ~= nil then
    -- Mappings for code commenting
    vim.api.nvim_set_keymap("x", "gc", "<Plug>VSCodeCommentary", {})
    vim.api.nvim_set_keymap("n", "gc", "<Plug>VSCodeCommentary", {})
    vim.api.nvim_set_keymap("o", "gc", "<Plug>VSCodeCommentary", {})
    vim.api.nvim_set_keymap("n", "gcc", "<Plug>VSCodeCommentaryLine", {})

    -- Workaround for executing visual selection in VS Code (for example, in Python
    -- interactive window)
    local esc = vim.api.nvim_replace_termcodes([[<Esc>]], true, true, true)

    local vscode_execute_line_or_selection = function(cur_mode, vscode_command)
      local visual_mode
      if cur_mode == "normal" then
        -- Visually select current line
        vim.cmd([[normal! V]])
        visual_mode = "V"
      else
        -- My guess is that this is probably needed because visual selection is
        -- 'reset' before function is called
        vim.cmd([[normal! gv]])
        visual_mode = vim.fn.visualmode()
      end

      if visual_mode == "V" then
        vim.fn.VSCodeNotifyRange(vscode_command, vim.fn.line("v"), vim.fn.line("."), 1)
      else
        local start_pos, end_pos = vim.fn.getpos([['<]]), vim.fn.getpos([['>]])
        -- `getpos()` returns `{bufnum, lnum, col, off}`, only 2 and 3 are needed
        vim.fn.VSCodeNotifyRangePos(vscode_command, start_pos[2], end_pos[2], start_pos[3], end_pos[3] + 1, 1)
      end

      -- Waite some time because otherwise following commands, when working
      -- remotely, seem to be executed before sending range to remote computer
      -- which upon delivery will execute the wrong range (usually a single line
      -- after desired selection)
      vim.cmd([[sleep 100m]])

      -- Escape to normal mode and move past selection (depending on visual mode).
      if visual_mode == "v" then
        vim.cmd(string.format([[normal! %s`>l]], esc))
      else
        vim.cmd(string.format([[normal! %s'>j]], esc))
      end
    end
  end
end
