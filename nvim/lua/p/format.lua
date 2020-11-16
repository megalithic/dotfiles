-- [ format.nvim ] ----------------------------------------------------------
--   https://github.com/lukas-reineke/format.nvim

require("format").setup(
  {
    ["*"] = {
      {cmd = {"sed -i 's/[ \t]*$//'"}} -- remove trailing whitespace
    },
    vim = {
      {
        cmd = {"luafmt -w replace"},
        start_pattern = "^lua << EOF$",
        end_pattern = "^EOF$"
      }
    },
    lua = {
      {
        cmd = {
          function(file)
            return string.format(
              "luafmt -l %s -w replace --indent-count 2 %s",
              vim.bo.textwidth,
              file
            )
          end
        }
      }
    },
    go = {
      {
        cmd = {"gofmt -w", "goimports -w"},
        tempfile_postfix = ".tmp"
      }
    },
    javascript = {
      {
        cmd = {"prettier -w", "./node_modules/.bin/eslint --fix"}
      }
    },
    python = {
      {
        cmd = {"black"}
      }
    },
    typescript = {
      {
        cmd = {"prettier -w", "./node_modules/.bin/eslint --fix"}
      }
    },
    -- elixir = {
    --   {
    --     cmd = {"mix format -"}
    --   }
    -- },
    markdown = {
      {cmd = {"prettier -w"}},
      {
        cmd = {"black"},
        start_pattern = "^```python$",
        end_pattern = "^```$",
        target = "current"
      },
      {
        cmd = {"qmlformat -i"},
        start_pattern = "^```qml$",
        end_pattern = "^```$",
        target = "current"
      },
      {
        cmd = {"clang-format -i"},
        start_pattern = "^```cpp$",
        end_pattern = "^```$",
        target = "current"
      }
    },
    cpp = {
      {
        cmd = {"clang-format -i"}
      }
    },
    qml = {
      {
        cmd = {"qmlformat -i"}
      }
    },
    json = {
      {
        cmd = {"js-beautify -s 2"}
      }
    }
  }
)
-- vim.fn.nvim_buf_set_keymap(
--   0,
--   "n",
--   "<leader>F",
--   "<cmd>Format<CR>",
--   {noremap = true, silent = true}
-- )
