local M = {}

M.map_opts = {noremap = false, silent = true, expr = false}

function M.cmd_map(cmd)
    return string.format('<cmd>%s<cr>', cmd)
end

function M.vcmd_map(cmd)
    return string.format([[<cmd>'<,'>%s<cr>]], cmd)
end

function M.autocmd(cmd) 
    vim.cmd("autocmd " .. cmd) 
end

function M.map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend('force', M.map_opts, opts or {})
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

function M.create_mappings(mappings, bufnr)
    local fn = vim.api.nvim_set_keymap
    if bufnr then
        fn = function(...)
            vim.api.nvim_buf_set_keymap(bufnr, ...)
        end
    end

    for mode, rules in pairs(mappings) do
        for _, m in ipairs(rules) do
            fn(mode, m.lhs, m.rhs, m.opts or {})
        end
    end
end

function new_command(s)
    vim.cmd('command! ' .. s)
end

function M.exec_cmds(cmd_list)
    vcmd(table.concat(cmd_list, '\n'))
end

function augroup(name, commands)
    vim.cmd('augroup ' .. name)
    vim.cmd('autocmd!')
    for _, c in ipairs(commands) do
        vim.cmd(string.format('autocmd %s %s %s %s', table.concat(c.events, ','),
                table.concat(c.targets, ','), table.concat(c.modifiers or {}, ' '),
            c.command))
    end
    vim.cmd('augroup END')
end

return M
