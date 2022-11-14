if not mega then return end
if not vim.g.enabled_plugin["vscode"] and not vim.g.vscode and vim.g.vscode ~= 1 then return end

print("test from vscode plugin")
-- Map("n", "z=", "vim.fn.VSCodeNotify('keyboard-quickfix.openQuickFix')<cr>", Opts)
--
local default_opts = { remap = false }
local function call_vs_code(command)
  return function ()
    vim.fn.VSCodeNotify(command)
  end
end

local function only_command()
  vim.fn.VSCodeNotify('workbench.action.closeEditorsInOtherGroups')
  vim.fn.VSCodeNotify('workbench.action.maximizeEditor')
  vim.fn.VSCodeNotify('workbench.action.closePanel')
end

-- vim.keymap.set('n', '-', call_vs_code('breadcrumbs.focusAndSelect'), default_opts)
vim.keymap.set('n', '<C-w>o', only_command, default_opts)
-- vim.keymap.set('n', '<leader>d', call_vs_code('gitlens.diffWithRevision'), default_opts)
vim.keymap.set('n', '<leader>g', call_vs_code('git.openFile'), default_opts)
-- vim.keymap.set('n', '<leader>t', call_vs_code('workbench.action.tasks.runTask'), default_opts)
-- vim.keymap.set('n', '<leader>v', call_vs_code('open-in-vim.open'), default_opts)
-- vim.keymap.set('n', '[d', call_vs_code('editor.action.marker.prev'), default_opts)
-- vim.keymap.set('n', '[q', call_vs_code('search.action.focusPreviousSearchResult'), default_opts)
-- vim.keymap.set('n', ']d', call_vs_code('editor.action.marker.next'), default_opts)
-- vim.keymap.set('n', ']q', call_vs_code('search.action.focusNextSearchResult'), default_opts)
-- vim.keymap.set('n', 'gb', call_vs_code('editor.debug.action.toggleBreakpoint'), default_opts)
