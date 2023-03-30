-- local border, highlight, L = as.ui.current.border, as.highlight, vim.log.levels
local border, L = mega.get_border(), vim.log.levels

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  enabled = false,
  version = "*",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    cmdline = {
      format = {
        IncRename = { title = "Rename" },
        substitute = { pattern = "^:%%?s/", icon = " ", ft = "regex", title = "" },
      },
    },
    lsp = {
      documentation = {
        opts = {
          border = { style = border },
          position = { row = 2 },
        },
      },
      signature = {
        enabled = true,
        opts = {
          position = { row = 2 },
        },
      },
      hover = { enabled = true },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    views = {
      vsplit = { size = { width = "auto" } },
      split = { win_options = { winhighlight = { Normal = "Normal" } } },
      popup = {
        border = { style = border, padding = { 0, 1 } },
      },
      cmdline_popup = {
        position = { row = 5, col = "50%" },
        size = { width = "auto", height = "auto" },
        border = { style = border, padding = { 0, 1 } },
      },
      confirm = {
        border = { style = border, padding = { 0, 1 }, text = { top = "" } },
      },
      popupmenu = {
        relative = "editor",
        position = { row = 9, col = "50%" },
        size = { width = 60, height = 10 },
        border = { style = border, padding = { 0, 1 } },
        win_options = { winhighlight = { Normal = "NormalFloat", FloatBorder = "FloatBorder" } },
      },
    },
    redirect = { view = "popup", filter = { event = "msg_show" } },
    routes = {
      {
        opts = { skip = true },
        filter = {
          any = {
            { event = "msg_show", find = "written" },
            { event = "msg_show", find = "%d+ lines, %d+ bytes" },
            { event = "msg_show", kind = "search_count" },
            { event = "msg_show", find = "%d+L, %d+B" },
            { event = "msg_show", find = "^Hunk %d+ of %d" },
            -- TODO: investigate the source of this LSP message and disable it happens in typescript files
            { event = "notify", find = "No information available" },
          },
        },
      },
      {
        view = "vsplit",
        filter = { event = "msg_show", min_height = 20 },
      },
      {
        view = "notify",
        filter = {
          any = {
            { event = "msg_show", min_height = 10 },
            { event = "msg_show", find = "Treesitter" },
          },
        },
        opts = { timeout = 10000 },
      },
      {
        view = "mini",
        filter = { any = { { event = "msg_show", find = "^E486:" } } }, -- minimise pattern not found messages
      },
      {
        view = "notify",
        filter = {
          any = {
            { warning = true },
            { event = "msg_show", find = "^Warn" },
            { event = "msg_show", find = "^W%d+:" },
            { event = "msg_show", find = "^No hunks$" },
          },
        },
        opts = { title = "Warning", level = L.WARN, merge = false, replace = false },
      },
      {
        view = "notify",
        opts = { title = "Error", level = L.ERROR, merge = true, replace = false },
        filter = {
          any = {
            { error = true },
            { event = "msg_show", find = "^Error" },
            { event = "msg_show", find = "^E%d+:" },
          },
        },
      },
      {
        view = "notify",
        opts = { title = "" },
        filter = { kind = { "emsg", "echo", "echomsg" } },
      },
    },
    commands = {
      history = { view = "vsplit" },
    },
    presets = {
      inc_rename = true,
      long_message_to_split = true,
      lsp_doc_border = true,
    },
  },
  config = function(_, opts)
    require("noice").setup(opts)

    -- highlight.plugin("noice", {
    --   { NoiceMini = { inherit = "MsgArea", bg = { from = "Normal" } } },
    --   { NoicePopupBaseGroup = { inherit = "NormalFloat", fg = { from = "DiagnosticSignInfo" } } },
    --   { NoicePopupWarnBaseGroup = { inherit = "NormalFloat", fg = { from = "Float" } } },
    --   { NoicePopupInfoBaseGroup = { inherit = "NormalFloat", fg = { from = "Conditional" } } },
    --   { NoiceCmdlinePopup = { bg = { from = "NormalFloat" } } },
    --   { NoiceCmdlinePopupBorder = { link = "FloatBorder" } },
    --   { NoiceCmdlinePopupBorderCmdline = { link = "NoicePopupBaseGroup" } },
    --   { NoiceCmdlinePopupBorderSearch = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlinePopupBorderFilter = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlinePopupBorderHelp = { link = "NoicePopupInfoBaseGroup" } },
    --   { NoiceCmdlinePopupBorderSubstitute = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlinePopupBorderIncRename = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlinePopupBorderInput = { link = "NoicePopupBaseGroup" } },
    --   { NoiceCmdlinePopupBorderLua = { link = "NoicePopupBaseGroup" } },
    --   { NoiceCmdlineIconCmdline = { link = "NoicePopupBaseGroup" } },
    --   { NoiceCmdlineIconSearch = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlineIconFilter = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlineIconHelp = { link = "NoicePopupInfoBaseGroup" } },
    --   { NoiceCmdlineIconIncRename = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlineIconSubstitute = { link = "NoicePopupWarnBaseGroup" } },
    --   { NoiceCmdlineIconInput = { link = "NoicePopupBaseGroup" } },
    --   { NoiceCmdlineIconLua = { link = "NoicePopupBaseGroup" } },
    --   { NoiceConfirm = { bg = { from = "NormalFloat" } } },
    --   { NoiceConfirmBorder = { link = "NoicePopupBaseGroup" } },
    -- })

    vim.keymap.set({ "n", "i", "s" }, "<c-f>", function()
      if not require("noice.lsp").scroll(4) then return "<c-f>" end
    end, { silent = true, expr = true })

    vim.keymap.set({ "n", "i", "s" }, "<c-b>", function()
      if not require("noice.lsp").scroll(-4) then return "<c-b>" end
    end, { silent = true, expr = true })

    vim.keymap.set("c", "<M-CR>", function() require("noice").redirect(vim.fn.getcmdline()) end, {
      desc = "redirect Cmdline",
    })
  end,
}
