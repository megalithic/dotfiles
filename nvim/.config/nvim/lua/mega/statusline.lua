-- local M = {}

-- M.section = {}
-- M.section.left = {}
-- M.section.right = {}
-- M.section.short_line_left = {}
-- M.section.short_line_right = {}
-- M.short_line_list = {}

-- function M.inactive_statusline()
--     local combine = function ()
--         local short_left_section = load_section(M.section.short_line_left,'left')
--         local short_right_section = load_section(M.section.short_line_right,'right')
--         local line = short_left_section .. '%=' .. short_right_section
--         return line
--     end
--     vim.wo.statusline = combine()
-- end

-- function M.active_statusline()
--     local sections = function()
--         local left_section = load_section(M.section.left,'left')
--         local right_section = load_section(M.section.right,'right')
--         local short_left_section = load_section(M.section.short_line_left,'left')
--         local short_right_section = load_section(M.section.short_line_right,'right')
--         if common.has_value(M.short_line_list,vim.bo.filetype) then
--             return short_left_section .. '%=' .. short_right_section
--         else
--             return  left_section .. '%=' .. right_section
--         end
--     end
--     vim.wo.statusline = sections()
--     colors.init_theme('nova', get_section)
--     -- register_user_events()
-- end

-- function M.init_colorscheme()
--     colors.init_theme('nova', get_section)
-- end

-- function M.disable_statusline()
--     vim.wo.statusline = ''
--     vim.api.nvim_command('augroup statusline')
--     vim.api.nvim_command('autocmd!')
--     vim.api.nvim_command('augroup END!')
-- end

-- function M.statusline_augroup()
--     local events = { 'FileType','BufWinEnter','BufReadPost','BufWritePost','BufEnter','WinEnter','FileChangedShellPost','VimResized' }
--     vim.api.nvim_command('augroup statusline')
--     vim.api.nvim_command('autocmd!')
--     for _, def in ipairs(events) do
--         local command = string.format('autocmd %s * lua require("statusline").active_statusline()',def)
--         vim.api.nvim_command(command)
--     end
--     vim.api.nvim_command('autocmd WinLeave * lua require("statusline").inactive_statusline()')
--     vim.api.nvim_command('augroup END')
-- end

-- return {}
