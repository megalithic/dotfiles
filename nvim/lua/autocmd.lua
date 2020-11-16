local vim = vim
local api = vim.api

--- This function is taken from https://github.com/norcalli/nvim_utils
local function nvim_create_augroups(definitions)
  for group_name, definition in pairs(definitions) do
    api.nvim_command('augroup '..group_name)
    api.nvim_command('autocmd!')
    for _, def in ipairs(definition) do
      local command = table.concat(vim.tbl_flatten{'autocmd', def}, ' ')
      api.nvim_command(command)
    end
    api.nvim_command('augroup END')
  end
end

local autocmds = {
  terminal_job = {
    { "TermOpen", "*", "startinsert" };
    { "TermOpen", "*", "setlocal listchars= nonumber norelativenumber" };
  };
  resize_windows_proportionally = {
    { "VimResized", "*", ":wincmd =" };
  };
  toggle_search_highlighting = {
    { "InsertEnter", "*", "setlocal nohlsearch" };
  };
  lua_highlight = {
    { "TextYankPost", "*", "silent! lua require'vim.highlight'.on_yank(\"IncSearch\", 1000)" };
  };
  scrollbar = {
    { "BufEnter",    "*", "silent! lua require('scrollbar').show()" };
    { "BufLeave",    "*", "silent! lua require('scrollbar').clear()" };

    { "CursorMoved", "*", "silent! lua require('scrollbar').show()" };
    { "VimResized",  "*", "silent! lua require('scrollbar').show()" };

    { "FocusGained", "*", "silent! lua require('scrollbar').show()"  };
    { "FocusLost",   "*", "silent! lua require('scrollbar').clear()" };
  };
}

nvim_create_augroups(autocmds)
