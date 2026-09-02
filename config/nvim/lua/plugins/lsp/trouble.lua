-- lua/plugins/lsp/trouble.lua
-- Trouble.nvim configuration with LSP symbol statusline integration
-- Adapted from alex35mil's config

mega.p.trouble = {}

local fn = {}

local DIAGNOSTICS_SOURCE = "diagnostics_per_ft"

-- ═══════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════════════════

---@return boolean true if trouble was open and is now closed
function mega.p.trouble.ensure_hidden()
  local trouble = require("trouble")
  if trouble.is_open() then
    trouble.close()
    return true
  end
  return false
end

--- Get the LSP document symbols statusline component
--- Used by lualine for tabline breadcrumb display
---@return table|nil statusline component with get() and has() methods
function mega.p.trouble.get_symbols_statusline()
  local ok, trouble = pcall(require, "trouble")
  if not ok then return nil end

  return trouble.statusline({
    mode = "lsp_document_symbols",
    groups = {},
    title = false,
    filter = { range = true },
    format = "{kind_icon:StatusBarSegmentFaded}{symbol.name:StatusBarSegmentFaded} ",
    hl_group = "StatusBarSegmentFaded",
  })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PLUGIN SPEC
-- ═══════════════════════════════════════════════════════════════════════════════

local spec = {
  "folke/trouble.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Trouble",
  keys = {
    {
      "<leader>xx",
      function()
        require("trouble").toggle("diagnostics")
      end,
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      function()
        require("trouble").toggle("diagnostics", { filter = { buf = 0 } })
      end,
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>xs",
      function()
        require("trouble").toggle("symbols", { focus = false })
      end,
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>xl",
      function()
        require("trouble").toggle("lsp", {
          focus = false,
          win = { position = "right" },
        })
      end,
      desc = "LSP Definitions / References (Trouble)",
    },
    {
      "<leader>xL",
      function()
        require("trouble").toggle("loclist")
      end,
      desc = "Location List (Trouble)",
    },
    {
      "<leader>xQ",
      function()
        require("trouble").toggle("qflist")
      end,
      desc = "Quickfix List (Trouble)",
    },

    -- Severity-filtered diagnostics
    {
      "<leader>xe",
      function()
        fn.open_diagnostics({ severity = vim.diagnostic.severity.ERROR })
      end,
      desc = "Errors (workspace)",
    },
    {
      "<leader>xE",
      function()
        fn.open_diagnostics({ buf = 0, severity = vim.diagnostic.severity.ERROR })
      end,
      desc = "Errors (buffer)",
    },
    {
      "<leader>xw",
      function()
        fn.open_diagnostics({ severity = vim.diagnostic.severity.WARN })
      end,
      desc = "Warnings (workspace)",
    },
    {
      "<leader>xW",
      function()
        fn.open_diagnostics({ buf = 0, severity = vim.diagnostic.severity.WARN })
      end,
      desc = "Warnings (buffer)",
    },
  },
  opts = {
    auto_close = false,
    auto_open = false,
    auto_preview = true,
    auto_refresh = true,
    auto_jump = false,
    focus = true,
    restore = true,
    follow = false,
    indent_guides = false,
    max_items = 200,
    multiline = true,
    pinned = false,
    warn_no_results = true,
    open_no_results = false,
    keys = {
      ["q"] = "close",
      ["<Esc>"] = "close",
      ["<CR>"] = "jump_close",
      ["<Right>"] = "fold_open",
      ["<S-Right>"] = "fold_open_recursive",
      ["<Left>"] = "fold_close",
      ["<S-Left>"] = "fold_close_recursive",
      ["<Space>"] = "fold_toggle",
      ["<S-Space>"] = "fold_toggle_recursive",
      ["<C-s>"] = "jump_split",
      ["<C-v>"] = "jump_vsplit",
    },
  },
  config = function(_, opts)
    local trouble = require("trouble")
    trouble.setup(opts)

    -- Register custom diagnostics source that filters by attached LSPs
    require("trouble.sources").register(DIAGNOSTICS_SOURCE, {
      get = function(cb)
        local Item = require("trouble.item")

        local items = {}
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        
        -- Build client name lookup for filtering
        local client_names = {}
        for _, client in ipairs(clients) do
          client_names[client.name] = true
        end

        -- Get all diagnostics and filter by attached LSP clients
        local all_diags = vim.diagnostic.get(nil)
        for _, d in ipairs(all_diags) do
          -- Only include diagnostics from LSPs attached to current buffer
          if d.source and client_names[d.source] then
            table.insert(
              items,
              Item.new({
                source = "diagnostics",
                buf = d.bufnr,
                pos = { d.lnum + 1, d.col },
                end_pos = { d.end_lnum and (d.end_lnum + 1) or nil, d.end_col },
                item = d,
              })
            )
          end
        end

        cb(items)
      end,
      config = {
        format = "{severity_icon} {message:md} {item.source} {code} {pos}",
        groups = {
          { "directory" },
          { "filename", format = "{file_icon} {basename} {count}" },
        },
        modes = {
          [DIAGNOSTICS_SOURCE] = {
            source = DIAGNOSTICS_SOURCE,
          },
        },
      },
    })
  end,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOCAL HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

function fn.open_diagnostics(filter)
  local trouble = require("trouble")

  trouble.open({
    mode = DIAGNOSTICS_SOURCE,
    focus = true,
    filter = filter,
    win = {
      size = 0.4,
      position = "bottom",
    },
  })
end

function fn.open_symbols()
  local trouble = require("trouble")

  trouble.open({
    mode = "symbols",
    focus = true,
    win = {
      size = { width = 0.3, height = 0.6 },
      position = "right",
    },
  })
end

return spec
