-- lua/plugins/test.lua
-- Test runner configuration
-- Uses vim-test with megaterm for output

return {
  {
    "vim-test/vim-test",
    dependencies = { "tpope/vim-projectionist" },
    cmd = { "TestNearest", "TestFile", "TestLast", "TestVisit", "TestSuite" },
    keys = {
      { "<localleader>tn", "<cmd>TestNearest<cr>", desc = "Test nearest" },
      { "<localleader>tf", "<cmd>TestFile<cr>", desc = "Test file" },
      { "<localleader>ta", "<cmd>TestFile<cr>", desc = "Test all (file)" },
      { "<localleader>tl", "<cmd>TestLast<cr>", desc = "Test last" },
      { "<localleader>ts", "<cmd>TestSuite<cr>", desc = "Test suite" },
      { "<localleader>tv", "<cmd>TestVisit<cr>", desc = "Test visit" },
      { "<localleader>tp", "<cmd>A<cr>", desc = "Alternate file" },
      { "<localleader>tP", "<cmd>AV<cr>", desc = "Alternate (vsplit)" },
    },
    config = function()
      local function notify_result(cmd, exit_code)
        if exit_code == 0 then
          vim.notify("✓ " .. cmd, vim.log.levels.INFO, { title = "Test Passed" })
        else
          vim.notify("✗ " .. cmd, vim.log.levels.ERROR, { title = "Test Failed" })
        end
      end

      -- Use megaterm for test output
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#start_normal"] = 1
      vim.g["test#preserve_screen"] = 1
      vim.g["test#filename_modifier"] = ":."

      -- Custom strategy using megaterm
      vim.g["test#custom_strategies"] = {
        megaterm = function(cmd)
          mega.term.create({
            cmd = cmd,
            position = "bottom",
            height = 20,
            start_insert = false,
            on_exit = function(_, exit_code)
              notify_result(cmd, exit_code)
            end,
          })
        end,
        megaterm_float = function(cmd)
          mega.term.create({
            cmd = cmd,
            position = "float",
            start_insert = false,
            on_exit = function(_, exit_code)
              notify_result(cmd, exit_code)
            end,
          })
        end,
      }

      -- Default to megaterm strategy
      vim.g["test#strategy"] = "megaterm"
    end,
  },

  -- Projectionist for alternate files
  {
    "tpope/vim-projectionist",
    lazy = false,
    init = function()
      vim.g.projectionist_heuristics = {
        -- Elixir
        ["mix.exs"] = {
          ["lib/*.ex"] = {
            alternate = "test/{}_test.exs",
            type = "source",
          },
          ["test/*_test.exs"] = {
            alternate = "lib/{}.ex",
            type = "test",
          },
        },
        -- Lua/Neovim
        ["lua/"] = {
          ["lua/*.lua"] = {
            alternate = "tests/{}_spec.lua",
            type = "source",
          },
          ["tests/*_spec.lua"] = {
            alternate = "lua/{}.lua",
            type = "test",
          },
        },
      }
    end,
  },
}
