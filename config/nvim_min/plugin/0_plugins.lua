local map = vim.keymap.set
local pack = vim.pack
local lsp = vim.lsp
local autocmd = vim.api.nvim_create_autocmd
local command = vim.api.nvim_create_user_command
local augroup = vim.api.nvim_create_augroup("mega_minvim", { clear = true })

pack.add({
  { src = "https://github.com/rktjmp/lush.nvim" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/chomosuke/typst-preview.nvim" },
})

do
  require("nvim-treesitter").setup()
  local treesitter_ensure_installed = {
    "svelte",
    "typescript",
    "tsx",
    "javascript",
    "jsx",
    "json",
    "toml",
    "yaml",
    "lua",
    "heex",
    "elixir",
    "bash",
    "comment",
    "markdown",
    "markdown_inline",
    "sh",
    "html",
    "css",
  }
  local installed = require("nvim-treesitter.config").get_installed("parsers")
  local not_installed = vim.tbl_filter(
    function(parser) return not vim.tbl_contains(installed, parser) end,
    treesitter_ensure_installed
  )
  if #not_installed > 0 then require("nvim-treesitter").install(not_installed) end

  local syntax_on = {
    asciidoc = true,
    elixir = true,
    php = true,
  }

  local group = vim.api.nvim_create_augroup("mega_minvim_treesitter", { clear = true })

  autocmd("FileType", {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      if filetype == "" then return end -- Stops if no filetype is detected.

      local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
      if not ok or not parser then
        -- vim.notify(string.format("Missing ts parser %s for bufnr %d", parser, bufnr), L.WARN)
        return
      end

      pcall(vim.treesitter.start)
      -- if vim.treesitter.language.add(filetype) then
      --   vim.treesitter.start(bufnr, filetype)
      -- else
      --   vim.notify(string.format("Missing ts parser for %s", filetype), L.WARN)
      -- end

      local ft = vim.bo[bufnr].filetype
      if syntax_on[ft] then vim.bo[bufnr].syntax = "on" end

      vim.schedule(function()
        -- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end)
    end,
  })

  autocmd("User", {
    group = group,
    pattern = "TSUpdate",
    callback = function()
      local parsers = require("nvim-treesitter.parsers")

      -- parsers.lua = {
      --   tier = 0,
      --
      --   ---@diagnostic disable-next-line: missing-fields
      --   install_info = {
      --     path = "~/plugins/tree-sitter-lua",
      --     files = { "src/parser.c", "src/scanner.c" },
      --   },
      -- }
    end,
  })

  autocmd("PackChanged", {
    desc = "Handle nvim-treesitter updates",
    group = augroup,
    callback = function(evt)
      if evt.data.kind == "update" then
        vim.notify("nvim-treesitter updated, running TSUpdate...", L.INFO)
        ---@diagnostic disable-next-line: param-type-mismatch
        local ok = pcall(vim.cmd, "TSUpdate")
        if ok then
          vim.notify("TSUpdate completed successfully!", L.INFO)
        else
          vim.notify("TSUpdate command not available yet, skipping", L.WARN)
        end
      end
    end,
  })
end

do
  function Oil_winbar()
    local path = vim.fn.expand("%")
    path = path:gsub("oil://", "")

    return "  " .. vim.fn.fnamemodify(path, ":.")
  end

  require("oil").setup({
    columns = {
      "icon",
      "permissions",
      "size",
      "mtime",
    },
    delete_to_trash = true,
    keymaps = {
      ["<CR>"] = {
        "actions.select",
        opts = { vertical = true, close = true },
        desc = "Open the entry in a vertical split",
      },
      ["<C-e>"] = { "actions.select", opts = {}, desc = "Open the entry in a current split" },
      ["<M-h>"] = "actions.select_split",
    },
    win_options = {
      winbar = "%{v:lua.Oil_winbar()}",
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _)
        local folder_skip = { "dev-tools.locks", "dune.lock", "_build" }
        return vim.tbl_contains(folder_skip, name)
      end,
    },
  })
end
