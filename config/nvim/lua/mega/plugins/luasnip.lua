return function()
  local ls = require("luasnip")

  local t = mega.replace_termcodes
  local types = require("luasnip.util.types")
  local extras = require("luasnip.extras")
  local fmt = require("luasnip.extras.fmt").fmt

  mega.augroup("LuasnipDiagnostics", {
    {
      event = "ModeChanged",
      pattern = "[is]:n",
      command = function()
        if ls.in_snippet() then
          return vim.diagnostic.enable()
        end
      end,
    },
    {
      event = "ModeChanged",
      pattern = "*:s",
      command = function()
        if ls.in_snippet() then
          return vim.diagnostic.disable()
        end
      end,
    },
  })

  ls.config.set_config({
    history = false,
    region_check_events = "CursorMoved,CursorHold,InsertEnter",
    delete_check_events = "InsertLeave",
    ext_opts = {
      [types.choiceNode] = {
        active = {
          hl_mode = "combine",
          virt_text = { { "●", "Operator" } },
        },
      },
      [types.insertNode] = {
        active = {
          hl_mode = "combine",
          virt_text = { { "●", "Type" } },
        },
      },
    },
    enable_autosnippets = true,
    snip_env = {
      fmt = fmt,
      m = extras.match,
      t = ls.text_node,
      f = ls.function_node,
      c = ls.choice_node,
      d = ls.dynamic_node,
      i = ls.insert_node,
      l = extras.lamda,
      snippet = ls.snippet,
    },
  })
  -- luasnip.config.set_config({
  --   history = true,
  --   updateevents = "TextChangedI",
  --   store_selection_keys = "<Tab>",
  --   ext_opts = {
  --     -- [types.insertNode] = {
  --     --   passive = {
  --     --     hl_group = "Substitute",
  --     --   },
  --     -- },
  --     [types.choiceNode] = {
  --       active = {
  --         virt_text = { { "choiceNode", "IncSearch" } },
  --       },
  --     },
  --   },
  --   enable_autosnippets = true,
  -- })

  -- TODO: we want to do our own luasnippets .. se this link for more details of
  -- how we might want to do this: https://youtu.be/Dn800rlPIho

  --- <tab> to jump to next snippet's placeholder
  local function on_tab()
    return ls.jump(1) and "" or t("<Tab>")
  end

  --- <s-tab> to jump to next snippet's placeholder
  local function on_s_tab()
    return ls.jump(-1) and "" or t("<S-Tab>")
  end

  local opts = { expr = true, remap = true }
  imap("<Tab>", on_tab, opts)
  smap("<Tab>", on_tab, opts)
  imap("<S-Tab>", on_s_tab, opts)
  smap("<S-Tab>", on_s_tab, opts)

  require("luasnip.loaders.from_lua").lazy_load()
  -- NOTE: the loader is called twice so it picks up the defaults first then my
  -- snippets. @see: https://github.com/L3MON4D3/LuaSnip/issues/364
  require("luasnip.loaders.from_vscode").lazy_load()
  -- require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
end
