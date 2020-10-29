local utils = require'utils'
local lsp_status = require('lsp-status')

local M = {}

---------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------

-- display lineNoIndicator (from drzel/vim-line-no-indicator)
local function line_no_indicator()
  local line_no_indicator_chars = {'⎺', '⎻', '─', '⎼', '⎽'}
  local current_line = vim.fn.line('.')
  local total_lines = vim.fn.line('$')
  local index = current_line

  if current_line == 1 then
    index = 1
  elseif current_line == total_lines then
    index = #line_no_indicator_chars
  else
    local line_no_fraction = math.floor(current_line) / math.floor(total_lines)
    index = math.ceil(line_no_fraction * #line_no_indicator_chars)
  end

  return line_no_indicator_chars[index]
end

---------------------------------------------------------------------------------
-- Main functions
---------------------------------------------------------------------------------

function M.git_info()
  if not vim.g.loaded_fugitive then
    return ''
  end

  local out = vim.fn.FugitiveHead(10)

  if out ~= '' then
    out = utils.get_icon('branch') .. '' .. out
  end

  return out
end

local indicators = {
  checking = '',
  warnings = '',
  errors = '',
  ok = '',
  info = '🛈',
  hint = '❗'
}

local spinner_frames = {'⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'}

local ale = {
  warnings = function(counts)
    local all_errors = counts['error'] + counts.style_error
    local all_non_errors = counts.total - all_errors
    return all_non_errors == 0 and '' or string.format('%s %d', indicators.warnings, all_non_errors)
  end,
  errors = function(counts)
    local all_errors = counts['error'] + counts.style_error
    return all_errors == 0 and '' or string.format('%s %d', indicators.errors, all_errors)
  end,
  ok = function(counts) return counts.total == 0 and indicators.ok or '' end,
  counts = function(buf) return vim.fn['ale#statusline#Count'](buf) end,
  enabled = function(buf)
    local ale_linted = vim.fn.getbufvar(buf, 'ale_linted', false)
    return ale_linted and ale_linted > 0
  end,
  frame_idx = 1,
  icon = ' 🍺 '
}

ale.checking = function(buf)
  local result = ''
  if vim.fn['ale#engine#IsCheckingBuffer'](buf) ~= 0 then
    result = spinner_frames[ale.frame_idx % #spinner_frames]
    ale.frame_idx = ale.frame_idx + 1
  else
    ale.frame_idx = 1
  end

  return result
end

setmetatable(ale, {
  __call = function(ale_tbl, buf)
    if not ale_tbl.enabled(buf) then return '' end

    local checking = ale_tbl.checking(buf)
    if checking ~= '' then return string.format('%s%s ', ale_tbl.icon, checking) end

    local counts = ale_tbl.counts(buf)
    local ok = ale_tbl.ok(counts)
    if ok ~= '' then return string.format('%s%s ', ale_tbl.icon, ok) end

    local warnings = ale_tbl.warnings(counts)
    local errors = ale_tbl.errors(counts)
    return string.format('%s%s%s%s ', ale_tbl.icon, warnings,
                         warnings == '' and '' or (errors == '' and '' or ' '), errors)
  end
})

-- function M.vcs(path)
--   local branch_sign = ''
--   local git_info = git.info(path)
--   if not git_info or git_info.branch == '' then return '' end
--   local changes = git_info.stats
--   local added = changes.added > 0 and ('+' .. changes.added .. ' ') or ''
--   local modified = changes.modified > 0 and ('~' .. changes.modified .. ' ') or ''
--   local removed = changes.removed > 0 and ('-' .. changes.removed .. ' ') or ''
--   local pad = ((added ~= '') or (removed ~= '') or (modified ~= '')) and ' ' or ''
--   local diff_str = string.format('%s%s%s%s', added, removed, modified, pad)
--   return string.format('%s%s %s ', diff_str, branch_sign, git_info.branch)
-- end

function M.lint_lsp(buf)
  local bufnr = buf or vim.fn.bufnr()
  local result = ale(bufnr)
  if #vim.lsp.buf_get_clients(bufnr) > 0 then result = result .. lsp_status.status() end
  return result
end

function M.update_filepath_highlights()
  if vim.bo.modified then
    vim.cmd('hi! link StatusLineFilePath DiffChange')
    vim.cmd('hi! link StatusLineNewFilePath DiffChange')
  else
    vim.cmd('hi! link StatusLineFilePath User6')
    vim.cmd('hi! link StatusLineNewFilePath User4')
  end

  return ''
end

function M.get_filepath_parts()
  local base = vim.fn.expand('%:~:.:h')
  local filename = vim.fn.expand('%:~:.:t')
  local prefix = (vim.fn.empty(base) == 1 or base == '.') and '' or base..'/'

  return { base, filename, prefix }
end

function M.filepath()
  local parts = M.get_filepath_parts()
  local prefix = parts[3]
  local filename = parts[2]

  local line = [[%{luaeval("require'statusline'.get_filepath_parts()[3]")}]]
  line = line .. '%*'
  line = line .. [[%{luaeval("require'statusline'.update_filepath_highlights()")}]]
  line = line .. '%#StatusLineFilePath#'
  line = line .. [[%{luaeval("require'statusline'.get_filepath_parts()[2]")}]]

  if vim.fn.empty(prefix) == 1 and vim.fn.empty(filename) == 1 then
    line = [[%{luaeval("require'statusline'.update_filepath_highlights()")}]]
    line = line .. '%#StatusLineNewFilePath#'
    line = line .. '%f'
    line = line .. '%*'
  end

  return line
end

function M.readonly()
  local is_modifiable = vim.bo.modifiable == true
  local is_readonly = vim.bo.readonly == true

  if not is_modifiable and is_readonly then
    return utils.get_icon('lock') .. ' RO'
  end

  if is_modifiable and is_readonly then
    return 'RO'
  end

  if not is_modifiable and not is_readonly then
    return utils.get_icon('lock')
  end

  return ''
end

local mode_table = {
  no          = 'N-Operator Pending',
  v           = 'V.',
  V           = 'V·Line',
  ['\22']     = 'V·Block', -- \<C-V>
  s           = 'S.',
  S           = 'S·Line',
  ['\19']     = 'S·Block.', -- \<C-S>
  i           = 'I.',
  ic          = 'I·Compl',
  ix          = 'I·X-Compl',
  R           = 'R.',
  Rc          = 'Compl·Replace',
  Rx          = 'V·Replace',
  Rv          = 'X-Compl·Replace',
  c           = 'Command',
  cv          = 'Vim Ex',
  ce          = 'Ex',
  r           = 'Propmt',
  rm          = 'More',
  ['r?']      = 'Confirm',
  ['r?']      = 'Sh',
  t           = 'T.',
}

function M.mode()
  return mode_table[vim.fn.mode()] or (vim.fn.mode() == 'n' and '' or 'NOT IN MAP')
end

function M.rhs()
  return vim.fn.winwidth(0) > 80 and
  ('%s %02d/%02d:%02d'):format(line_no_indicator(), vim.fn.line('.'), vim.fn.line('$'), vim.fn.col('.')) or
  line_no_indicator()
end

function M.spell()
  if vim.wo.spell then
    return utils.get_icon('spell')
  end
  return ''
end

function M.paste()
  if vim.o.paste then
    return utils.get_icon('paste')
  end
  return ''
end

function M.file_info()
  local line = vim.bo.filetype
  if vim.bo.fileformat ~= 'unix' then
    return line .. vim.bo.fileformat
  end

  if vim.bo.fileencoding ~= 'utf-8' then
    return line .. vim.bo.fileencoding
  end

  return line
end

function M.word_count()
  if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'text' then
    return vim.fn.wordcount()["words"] ..' words'
  end
  return ''
end

function M.filetype()
  return vim.bo.filetype
end

---------------------------------------------------------------------------------
-- Statusline
---------------------------------------------------------------------------------

function M.active()
  local line = [[%6*%{luaeval("require'statusline'.git_info()")} %*]]

  line = line .. '%<'
  line = line .. '%4*' .. M.filepath() .. '%*'
  line = line .. [[%4* %{luaeval("require'statusline'.word_count()")} %*]]
  line = line .. [[%5* %{luaeval("require'statusline'.readonly()")} %w %*]]
  line = line .. '%9*%=%*'
  line = line .. [[ %{luaeval("require'statusline'.mode()")} %*]]
  line = line .. [[%#ErrorMsg# %{luaeval("require'statusline'.paste()")} %*]]
  line = line .. [[%#WarningMsg# %{luaeval("require'statusline'.spell()")} %*]]
  line = line .. [[%4* %{luaeval("require'statusline'.lint_lsp()")} %*]]
  line = line .. [[%4* %{luaeval("require'statusline'.file_info()")} %*]]
  line = line .. [[%4* %{luaeval("require'statusline'.rhs()")} %*]]

  if vim.bo.filetype == 'help' or vim.bo.filetype == 'man' then
    line = [[%#StatusLineNC# %{luaeval("require'statusline'.filetype()")} %f]]
    line = line .. [[%5* %{luaeval("require'statusline'.readonly()")} %w %*]]
  end

  vim.api.nvim_win_set_option(0, 'statusline', line)
end

function M.inactive()
  local line = '%#StatusLineNC#%f%*'

  vim.api.nvim_win_set_option(0, 'statusline', line)
end


function M.activate()
  vim.cmd(('hi! StatusLine gui=NONE cterm=NONE guibg=NONE ctermbg=NONE guifg=%s ctermfg=%d'):format(utils.get_color('Identifier', 'fg', 'gui'), utils.get_color('Identifier', 'fg', 'cterm')))

  utils.augroup('MyStatusLine', function ()
    vim.cmd("autocmd WinEnter,BufEnter * lua require'statusline'.active()")
    vim.cmd("autocmd WinLeave,BufLeave * lua require'statusline'.inactive()")
  end)
end

return M
-- local utils = require('statusline_utils')
-- local git = require('git')
-- local lsp_status = require('lsp-status')

-- local indicators = {
--   checking = '',
--   warnings = '',
--   errors = '',
--   ok = '',
--   info = '🛈',
--   hint = '❗'
-- }

-- local spinner_frames = {'⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'}

-- local function icon() return utils.icons.lookup_filetype(vim.bo.filetype) end

-- local function filetype()
--   local ft = vim.bo.filetype
--   return ft ~= '' and ft or 'no filetype'
-- end

-- local ale = {
--   warnings = function(counts)
--     local all_errors = counts['error'] + counts.style_error
--     local all_non_errors = counts.total - all_errors
--     return all_non_errors == 0 and '' or string.format('%s %d', indicators.warnings, all_non_errors)
--   end,
--   errors = function(counts)
--     local all_errors = counts['error'] + counts.style_error
--     return all_errors == 0 and '' or string.format('%s %d', indicators.errors, all_errors)
--   end,
--   ok = function(counts) return counts.total == 0 and indicators.ok or '' end,
--   counts = function(buf) return vim.fn['ale#statusline#Count'](buf) end,
--   enabled = function(buf)
--     local ale_linted = vim.fn.getbufvar(buf, 'ale_linted', false)
--     return ale_linted and ale_linted > 0
--   end,
--   frame_idx = 1,
--   icon = ' 🍺 '
-- }

-- ale.checking = function(buf)
--   local result = ''
--   if vim.fn['ale#engine#IsCheckingBuffer'](buf) ~= 0 then
--     result = spinner_frames[ale.frame_idx % #spinner_frames]
--     ale.frame_idx = ale.frame_idx + 1
--   else
--     ale.frame_idx = 1
--   end

--   return result
-- end

-- setmetatable(ale, {
--   __call = function(ale_tbl, buf)
--     if not ale_tbl.enabled(buf) then return '' end

--     local checking = ale_tbl.checking(buf)
--     if checking ~= '' then return string.format('%s%s ', ale_tbl.icon, checking) end

--     local counts = ale_tbl.counts(buf)
--     local ok = ale_tbl.ok(counts)
--     if ok ~= '' then return string.format('%s%s ', ale_tbl.icon, ok) end

--     local warnings = ale_tbl.warnings(counts)
--     local errors = ale_tbl.errors(counts)
--     return string.format('%s%s%s%s ', ale_tbl.icon, warnings,
--                          warnings == '' and '' or (errors == '' and '' or ' '), errors)
--   end
-- })

-- local function vcs(path)
--   local branch_sign = ''
--   local git_info = git.info(path)
--   if not git_info or git_info.branch == '' then return '' end
--   local changes = git_info.stats
--   local added = changes.added > 0 and ('+' .. changes.added .. ' ') or ''
--   local modified = changes.modified > 0 and ('~' .. changes.modified .. ' ') or ''
--   local removed = changes.removed > 0 and ('-' .. changes.removed .. ' ') or ''
--   local pad = ((added ~= '') or (removed ~= '') or (modified ~= '')) and ' ' or ''
--   local diff_str = string.format('%s%s%s%s', added, removed, modified, pad)
--   return string.format('%s%s %s ', diff_str, branch_sign, git_info.branch)
-- end

-- local function lint_lsp(buf)
--   local result = ale(buf)
--   if #vim.lsp.buf_get_clients(buf) > 0 then result = result .. lsp_status.status() end
--   return result
-- end

-- local mode_table = {
--   n = 'Normal',
--   no = 'N·Operator Pending',
--   v = 'Visual',
--   V = 'V·Line',
--   ['^V'] = 'V·Block',
--   s = 'Select',
--   S = 'S·Line',
--   ['^S'] = 'S·Block',
--   i = 'Insert',
--   R = 'Replace',
--   Rv = 'V·Replace',
--   c = 'Command',
--   cv = 'Vim Ex',
--   ce = 'Ex',
--   r = 'Prompt',
--   rm = 'More',
--   ['r?'] = 'Confirm',
--   ['!'] = 'Shell',
--   t = 'Terminal'
-- }

-- local function get_mode(mode) return string.upper(mode_table[mode] or 'V-Block') end

-- local function filename(buf_name, win_id)
--   local base_name = vim.fn.fnamemodify(buf_name, [[:~:.]])
--   local space = math.min(60, math.floor(0.6 * vim.fn.winwidth(win_id)))
--   if string.len(base_name) <= space then
--     return base_name
--   else
--     return vim.fn.pathshorten(base_name)
--   end
-- end

-- local function update_colors(mode)
--   if mode == 'n' then
--     vim.cmd [[hi StatuslineAccent guibg=#d75f5f gui=bold guifg=#e9e9e9]]
--   elseif mode == 'i' then
--     vim.cmd [[hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#dab997]]
--   elseif mode == 'R' then
--     vim.cmd [[hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#afaf00]]
--   elseif mode == 'c' then
--     vim.cmd [[hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#83adad]]
--   elseif mode == 't' then
--     vim.cmd [[hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#6f6f6f]]
--   else
--     vim.cmd [[hi StatuslineAccent guifg=#e9e9e9 gui=bold guibg=#f485dd]]
--   end

--   if vim.bo.modified then
--     vim.cmd [[hi StatuslineFilename guifg=#d75f5f gui=bold guibg=#3a3a3a]]
--   else
--     vim.cmd [[hi StatuslineFilename guifg=#e9e9e9 gui=bold guibg=#3a3a3a]]
--   end
-- end

-- local function set_modified_symbol(modified)
--   if modified then
--     vim.cmd [[hi StatuslineModified guibg=#3a3a3a gui=bold guifg=#d75f5f]]
--     return '  ●'
--   else
--     vim.cmd [[ hi StatuslineModified guibg=#3a3a3a gui=bold guifg=#afaf00]]
--     return ''
--   end
-- end

-- local function get_paste() return vim.o.paste and 'PASTE ' or '' end

-- local function get_readonly_space()
--   return ((vim.o.paste and vim.bo.readonly) and ' ' or '') and '%r'
--            .. (vim.bo.readonly and ' ' or '')
-- end

-- local function status()
--   local mode = vim.fn.mode()
--   local buf_nr = vim.fn.bufnr()
--   local buf_name = vim.fn.bufname()
--   local buf_path = vim.fn.resolve(vim.fn.fnamemodify(buf_name, ':p'))
--   local win_id = vim.fn.win_getid()

--   update_colors(mode)
--   local line_components = {}
--   table.insert(line_components, '%#StatuslineAccent# ' .. get_mode(mode) .. ' ')
--   table.insert(line_components, '%#StatuslineFiletype# ' .. icon())
--   table.insert(line_components, '%#StatuslineModified#' .. set_modified_symbol(vim.bo.modified))
--   table.insert(line_components, '%#StatuslineFilename# ' .. filename(buf_name, win_id) .. ' %<')
--   table.insert(line_components, '%#StatuslineFilename# ' .. get_paste())
--   table.insert(line_components, get_readonly_space())
--   table.insert(line_components, '%#StatuslineLineCol#(Ln %l/%L, %#StatuslineLineCol#Col %c) %<')
--   table.insert(line_components, '%=')
--   table.insert(line_components, '%#StatuslineVC#' .. vcs(buf_path) .. ' ')
--   table.insert(line_components, '%#StatuslineLint#' .. lint_lsp(buf_nr) .. '%#StatuslineFiletype#')
--   return table.concat(line_components, '')
-- end

-- return status
