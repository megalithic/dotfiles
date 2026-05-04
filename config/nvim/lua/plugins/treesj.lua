-- lua/plugins/treesj.lua
-- Split/join code blocks (arrays, objects, function args, etc.)
-- Reference: https://github.com/chrisgrieser/.config/blob/main/nvim/lua/plugin-specs/treesj.lua

return {
  "Wansmer/treesj",
  keys = {
    {
      "<localleader>J",
      function() require("treesj").toggle() end,
      desc = "Split/join lines",
    },
    {
      "<localleader>J",
      function() require("treesj").toggle({ split = { recursive = true } }) end,
      desc = "Split/join recursive",
    },
  },
  opts = {
    use_default_keymaps = false,
    cursor_behavior = "start",
    max_join_length = 120,
    langs = {
      -- JavaScript/TypeScript: handle if-statement blocks
      javascript = {
        statement_block = {
          join = {
            format_tree = function(tsj)
              -- Remove braces when joining if-statements
              if tsj:tsnode():parent():type() == "if_statement" then
                tsj:remove_child({ "{", "}" })
                tsj:update_preset({ recursive = false }, "join")
              else
                require("treesj.langs.javascript").statement_block.join.format_tree(tsj)
              end
            end,
          },
        },
      },
      -- Elixir: handle do blocks
      elixir = {
        do_block = {
          both = {
            separator = "",
          },
        },
      },
      -- Lua: ensure proper formatting
      lua = {
        table_constructor = {
          both = {
            separator = ",",
            last_separator = true,
          },
        },
      },
    },
  },
  config = function(_, opts)
    -- Extend TypeScript with JavaScript config
    opts.langs.typescript = opts.langs.javascript
    opts.langs.typescriptreact = opts.langs.javascript
    opts.langs.javascriptreact = opts.langs.javascript
    require("treesj").setup(opts)
  end,
}
