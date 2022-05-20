return function(plug)
  if plug == nil then
    return
  end

  -- TODO: use vim.json.decode([[]])?
  -- REF: https://github.com/mhanberg/.dotfiles/blob/2ae15a001ed8fffbe0305512676ff7aed1586436/config/nvim/init.lua#L97
  vim.g.projectionist_heuristics = {
    ["&package.json"] = {
      ["package.json"] = {
        type = "package",
        alternate = { "yarn.lock", "package-lock.json" },
      },
      ["package-lock.json"] = {
        alternate = "package.json",
      },
      ["yarn.lock"] = {
        alternate = "package.json",
      },
    },
    ["package.json"] = {
      -- outstand'ing (ts/tsx)
      ["spec/javascript/*.test.tsx"] = {
        ["alternate"] = "app/webpacker/src/javascript/{}.tsx",
        ["type"] = "test",
      },
      ["app/webpacker/src/javascript/*.tsx"] = {
        ["alternate"] = "spec/javascript/{}.test.tsx",
        ["type"] = "source",
      },
      ["spec/javascript/*.test.ts"] = {
        ["alternate"] = "app/webpacker/src/javascript/{}.ts",
        ["type"] = "test",
      },
      ["app/webpacker/src/javascript/*.ts"] = {
        ["alternate"] = "spec/javascript/{}.test.ts",
        ["type"] = "source",
      },
    },
    -- https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/after/ftplugin/elixir.vim
    ["mix.exs"] = {
      -- "dead" views
      ["lib/**/views/*_view.ex"] = {
        ["type"] = "view",
        ["alternate"] = "test/{dirname}/views/{basename}_view_test.exs",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
          "  use {dirname|camelcase|capitalize}, :view",
          "end",
        },
      },
      ["test/**/views/*_view_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{dirname}/views/{basename}_view.ex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
          "end",
        },
      },
      -- "live" views
      ["lib/**/live/*_live.ex"] = {
        ["type"] = "live",
        ["alternate"] = "test/{dirname}/live/{basename}_live_test.exs",
        ["related"] = "lib/{dirname}/live/{basename}_live.html.heex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
          "  use {dirname|camelcase|capitalize}, :live_view",
          "end",
        },
      },
      ["lib/**/live/*_live.html.heex"] = {
        ["type"] = "heex",
        ["related"] = "lib/{dirname}/live/{basename}_live.html.heex",
      },
      ["test/**/live/*_live_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{dirname}/live/{basename}_live.ex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
          -- "  use ExUnit.Case, async: true",
          "  use {dirname|camelcase|capitalize}.ConnCase",
          "  import Phoenix.LiveViewTest",
          -- "",
          -- "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
          "end",
        },
      },
      -- ["lib/*.ex"] = {
      --   ["type"] = "source",
      --   ["alternate"] = "test/{}_test.exs",
      --   ["template"] = {
      --     "defmodule {camelcase|capitalize|dot} do",
      --     "",
      --     "end",
      --   },
      -- },
      -- ["test/*_test.exs"] = {
      --   ["type"] = "test",
      --   ["alternate"] = "lib/{}.ex",
      --   ["template"] = {
      --     "defmodule {camelcase|capitalize|dot}Test do",
      --     "  use ExUnit.Case, async: true",
      --     "",
      --     "  alias {camelcase|capitalize|dot}",
      --     "end",
      --   },
      -- },
    },
  }
end
