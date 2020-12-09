return function(_) -- bufnr
    -- ## plasticboy/vim-markdown	
    vim.g.markdown_fenced_languages = { 
        'javascript', 'js=javascript', 'json=javascript',	
        'css', 'scss', 'sass',	
        'ruby', 'erb=eruby',	
        'python',	
        'haml', 'html',	
        'bash=sh', 'zsh', 'elm', 'elixir', 'eelixir' }	
    vim.g.vim_markdown_folding_disabled = 1	
    vim.g.vim_markdown_conceal = 0	
    vim.g.vim_markdown_conceal_code_blocks = 0	
    vim.g.vim_markdown_folding_style_pythonic = 0	
    vim.g.vim_markdown_override_foldtext = 0	
    vim.g.vim_markdown_follow_anchor = 1	
    vim.g.vim_markdown_frontmatter = 1	
    vim.g.vim_markdown_new_list_item_indent = 2	
    vim.g.vim_markdown_auto_insert_bullets = 0	
    vim.g.vim_markdown_no_extensions_in_markdown = 1	
    vim.g.vim_markdown_math=1	
    vim.g.vim_markdown_strikethrough=1	

    vim.cmd([[set conceallevel=2]])
end 
