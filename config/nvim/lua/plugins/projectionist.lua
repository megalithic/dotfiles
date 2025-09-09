return {

  {
    "rgroli/other.nvim",
    cond = false,
    opts = {
      mappings = {
        "livewire",
        "angular",
        "laravel",
        "rails",
        "golang",
      },
    },
    config = function()
      -- https://github.com/rgroli/other.nvim/blob/main/lua/other-nvim/builtin/mappings/rails.lua
    end,
  },
  {
    "tpope/vim-projectionist",
    event = { "LazyFile" },
    ft = { "elixir", "javascript", "typescript", "heex", "eelixir", "surface" },
    config = function()
      vim.g.projectionist_heuristics = {
        ["mix.exs"] = {
          ["lib/**/views/*_view.ex"] = {
            type = "view",
            alternate = "test/{dirname}/views/{basename}_view_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
              "  use {dirname|camelcase|capitalize}, :view",
              "end",
            },
          },
          ["test/**/views/*_view_test.exs"] = {
            type = "test",
            alternate = "lib/{dirname}/views/{basename}_view.ex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
              "  use ExUnit.Case, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
              "end",
            },
          },
          ["lib/**/controllers/*_controller.ex"] = {
            type = "controller",
            alternate = "test/{dirname}/controllers/{basename}_controller_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
              "  use {dirname|camelcase|capitalize}, :controller",
              "end",
            },
          },
          ["test/**/controllers/*_controller_test.exs"] = {
            type = "test",
            alternate = "lib/{dirname}/controllers/{basename}_controller.ex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
              "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
              "end",
            },
          },
          ["lib/**/controllers/*_html.ex"] = {
            type = "html",
            alternate = "test/{dirname}/controllers/{basename}_html_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTML do",
              "  use {dirname|camelcase|capitalize}, :html",
              "",
              [[  embed_templates "{basename|snakecase}_html/*"]],
              "end",
            },
          },
          ["test/**/controllers/*_html_test.exs"] = {
            type = "test",
            alternate = "lib/{dirname}/controllers/{basename}_html.ex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTMLTest do",
              "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}HTML",
              "end",
            },
          },
          ["lib/**/components/*.ex"] = {
            type = "component",
            alternate = "test/{dirname}/components/{basename}_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize} do",
              "  use Phoenix.Component",
              "end",
            },
          },
          ["lib/**/components/*.html.heex"] = {
            type = "html",
            alternate = "lib/{dirname}/components/{basename}.ex",
          },
          ["test/**/components/*_test.exs"] = {
            type = "test",
            alternate = "lib/{dirname}/components/{basename}.ex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
              "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}",
              "end",
            },
          },
          ["lib/**/live/*_live.ex"] = {
            type = "liveview",
            alternate = "test/{dirname}/live/{basename}_live_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
              "  use {dirname|camelcase|capitalize}, :live_view",
              "end",
            },
          },
          ["lib/**/live/*_live.html.heex"] = {
            type = "html",
            alternate = "lib/{dirname}/live/{basename}_live.ex",
          },
          ["test/**/live/*_live_test.exs"] = {
            type = "test",
            alternate = "lib/{dirname}/live/{basename}_live.ex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
              "  use {dirname|camelcase|capitalize}.ConnCase",
              "",
              "  import Phoenix.LiveViewTest",
              "end",
            },
          },
          ["lib/**/live/*_component.ex"] = {
            type = "livecomponent",
            alternate = "lib/{dirname}/live/{basename}_component.html.heex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
              "  use {dirname|camelcase|capitalize}, :live_view",
              "end",
            },
          },
          ["lib/**/live/*_component.html.heex"] = {
            type = "html",
            alternate = "lib/{dirname}/live/{basename}_component.ex",
          },
          ["lib/**/channels/*_channel.ex"] = {
            type = "channel",
            alternate = "test/{dirname}/channels/{basename}_channel_test.exs",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
              "  use {dirname|camelcase|capitalize}, :channel",
              "end",
            },
          },
          ["test/**/channels/*_channel_test.exs"] = {
            type = "test",
            alternate = "lib/{dirname}/channels/{basename}_channel.ex",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
              "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
              "",
              "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
              "end",
            },
          },
          ["test/**/features/*_test.exs"] = {
            type = "feature",
            template = {
              "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
              "  use {dirname|camelcase|capitalize}.FeatureCase, async: true",
              "end",
            },
          },
          ["lib/*.ex"] = {
            type = "source",
            alternate = "test/{}_test.exs",
            template = { "defmodule {camelcase|capitalize|dot} do", "end" },
          },
          ["test/*_test.exs"] = {
            type = "test",
            alternate = "lib/{}.ex",
            template = {
              "defmodule {camelcase|capitalize|dot}Test do",
              "  use ExUnit.Case, async: true",
              "",
              "  alias {camelcase|capitalize|dot}",
              "end",
            },
          },
        },
      }
      -- vim.g.projectionist_heuristics = {
      --   ["mix.exs"] = {
      --     --         "*_live.ex": {
      --     --           "type": "live",
      --     --           "alternate": "test/{dirname}/live/{basename}_live_test.exs",
      --     --           "related": ["{dirname|dirname|dirname}/live/{dirname|basename}_live.html.heex"],
      --     --           "template": [
      --     --             "defmodule Web.{basename|camelcase|capitalize}Live do",
      --     --             "  use Phoenix.LiveView",
      --     --             "",
      --     --             "  def render(assigns) do",
      --     --             "    ~L\"\"\"",
      --     --             "    <div class=\"\">",
      --     --             "      Hello from {basename}",
      --     --             "    </div>",
      --     --             "    \"\"\"",
      --     --             "  end",
      --     --             "",
      --     --             "  def mount(_params, _session, socket) do",
      --     --             "    {open}:ok, socket{close}",
      --     --             "  end",
      --     --             "end"
      --     --           ]
      --     --         },
      --     --         "*heex": {
      --     --           "type": "heex",
      --     --           "related": [
      --     --             "{dirname|dirname|dirname}/controllers/{dirname|basename}_controller.ex",
      --     --             "{dirname|dirname|dirname}/live/{dirname|basename}_live.ex"
      --     --           ],
      --     --           "template": ["<h1 style=\"color: #C7AA8D; font-size:3em;\">{basename}.heex template</h1>"]
      --     --         }
      --     ["lib/**/live/*_live.ex"] = {
      --       type = "live",
      --       alternate = "test/{dirname}/live/{basename}_live_test.exs",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
      --         "  use {dirname|camelcase|capitalize}, :live_view",
      --         "end",
      --       },
      --     },
      --     ["test/**/live/*_live_test.exs"] = {
      --       type = "test",
      --       alternate = "lib/{dirname}/live/{basename}_live.ex",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
      --         "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
      --         "end",
      --       },
      --     },
      --     ["lib/**/controllers/*_controller.ex"] = {
      --       type = "controller",
      --       alternate = "test/{dirname}/controllers/{basename}_controller_test.exs",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
      --         "  use {dirname|camelcase|capitalize}, :controller",
      --         "end",
      --       },
      --     },
      --     ["test/**/controllers/*_controller_test.exs"] = {
      --       alternate = "lib/{dirname}/controllers/{basename}_controller.ex",
      --       type = "test",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
      --         "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
      --         "end",
      --       },
      --     },
      --     ["lib/**/channels/*_channel.ex"] = {
      --       type = "channel",
      --       alternate = "test/{dirname}/channels/{basename}_channel_test.exs",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
      --         "  use {dirname|camelcase|capitalize}, :channel",
      --         "end",
      --       },
      --     },
      --     ["test/**/channels/*_channel_test.exs"] = {
      --       alternate = "lib/{dirname}/channels/{basename}_channel.ex",
      --       type = "test",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
      --         "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
      --         "",
      --         "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
      --         "end",
      --       },
      --     },
      --     ["test/**/features/*_test.exs"] = {
      --       type = "feature",
      --       template = {
      --         "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
      --         "  use {dirname|camelcase|capitalize}.FeatureCase, async: true",
      --         "end",
      --       },
      --     },
      --     ["lib/*.ex"] = {
      --       alternate = "test/{}_test.exs",
      --       type = "source",
      --       template = { "defmodule {camelcase|capitalize|dot} do", "end" },
      --     },
      --     ["test/*_test.exs"] = {
      --       alternate = "lib/{}.ex",
      --       type = "test",
      --       template = {
      --         "defmodule {camelcase|capitalize|dot}Test do",
      --         "  use ExUnit.Case, async: true",
      --         "",
      --         "  alias {camelcase|capitalize|dot}",
      --         "end",
      --       },
      --     },
      --   },
      -- }
      -- TODO: use vim.json.decode([[]])?
      -- REF: https://github.com/mhanberg/.dotfiles/blob/2ae15a001ed8fffbe0305512676ff7aed1586436/config/nvim/init.lua#L97
      -- vim.g.projectionist_heuristics = vim.json.decode([[
      --     {
      --       "mix.exs": {
      --         "lib/**/views/*_view.ex": {
      --           "type": "view",
      --           "alternate": "test/{dirname}/views/{basename}_view_test.exs",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do", "  use {dirname|camelcase|capitalize}, :view", "end" ] },
      --         "test/**/views/*_view_test.exs": {
      --           "alternate": "lib/{dirname}/views/{basename}_view.ex",
      --           "type": "test",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
      --             "  use ExUnit.Case, async: true",
      --             "",
      --             "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
      --             "end"
      --           ]
      --         },
      --         "lib/**/controllers/*_controller.ex": {
      --           "type": "controller",
      --           "alternate": "test/{dirname}/controllers/{basename}_controller_test.exs",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
      --             "  use {dirname|camelcase|capitalize}, :controller",
      --             "end"
      --           ]
      --         },
      --         "test/**/controllers/*_controller_test.exs": {
      --           "alternate": "lib/{dirname}/controllers/{basename}_controller.ex",
      --           "type": "test",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
      --             "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
      --             "end"
      --           ]
      --         },
      --         "lib/**/channels/*_channel.ex": {
      --           "type": "channel",
      --           "alternate": "test/{dirname}/channels/{basename}_channel_test.exs",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
      --             "  use {dirname|camelcase|capitalize}, :channel",
      --             "end"
      --           ]
      --         },
      --         "test/**/channels/*_channel_test.exs": {
      --           "alternate": "lib/{dirname}/channels/{basename}_channel.ex",
      --           "type": "test",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
      --             "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
      --             "",
      --             "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
      --             "end"
      --           ]
      --         },
      --         "test/**/features/*_test.exs": {
      --           "type": "feature",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
      --             "  use {dirname|camelcase|capitalize}.FeatureCase, async: true",
      --             "end"
      --           ]
      --         },
      --         "lib/*.ex": {
      --           "alternate": "test/{}_test.exs",
      --           "type": "source",
      --           "template": ["defmodule {camelcase|capitalize|dot} do", "end"]
      --         },
      --         "test/*_test.exs": {
      --           "alternate": "lib/{}.ex",
      --           "type": "test",
      --           "template": [
      --             "defmodule {camelcase|capitalize|dot}Test do",
      --             "  use ExUnit.Case, async: true",
      --             "",
      --             "  alias {camelcase|capitalize|dot}",
      --             "end"
      --           ]
      --         },
      --         "*_live.ex": {
      --           "type": "live",
      --           "alternate": "test/{dirname}/live/{basename}_live_test.exs",
      --           "related": ["{dirname|dirname|dirname}/live/{dirname|basename}_live.html.heex"],
      --           "template": [
      --             "defmodule Web.{basename|camelcase|capitalize}Live do",
      --             "  use Phoenix.LiveView",
      --             "",
      --             "  def render(assigns) do",
      --             "    ~L\"\"\"",
      --             "    <div class=\"\">",
      --             "      Hello from {basename}",
      --             "    </div>",
      --             "    \"\"\"",
      --             "  end",
      --             "",
      --             "  def mount(_params, _session, socket) do",
      --             "    {open}:ok, socket{close}",
      --             "  end",
      --             "end"
      --           ]
      --         },
      --         "*heex": {
      --           "type": "heex",
      --           "related": [
      --             "{dirname|dirname|dirname}/controllers/{dirname|basename}_controller.ex",
      --             "{dirname|dirname|dirname}/live/{dirname|basename}_live.ex"
      --           ],
      --           "template": ["<h1 style=\"color: #C7AA8D; font-size:3em;\">{basename}.heex template</h1>"]
      --         }
      --         "*_view.ex": {
      --           "type": "view",
      --           "alternate": "test/{dirname}/views/{basename}_view_test.exs",
      --           "template": [
      --             "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
      --             "  use {dirname|camelcase|capitalize}, :view",
      --             "end"
      --           ]
      --         },
      --         "*eex": {
      --           "type": "template",
      --           "related": [
      --             "{dirname|dirname|dirname}/controllers/{dirname|basename}_controller.ex",
      --             "{dirname|dirname|dirname}/views/{dirname|basename}_view.ex"
      --           ],
      --           "template": ["<h1 style=\"color: #C7AA8D; font-size:3em;\">{basename}.eex template</h1>"]
      --         },
      --       }
      --     }
      --   ]])
    end,
  },
}
