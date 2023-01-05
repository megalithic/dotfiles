local M = {
  "tpope/vim-projectionist",
  ft = { "elixir", "javascript", "typescript" },
}

function M.config()
  vim.g.projectionist_heuristics = {
    ["mix.exs"] = {
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
      ["lib/**/live/*_live.ex"] = {
        type = "live",
        alternate = "test/{dirname}/live/{basename}_live_test.exs",
        template = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
          "  use {dirname|camelcase|capitalize}, :live_view",
          "end",
        },
      },
      ["test/**/live/*_live_test.exs"] = {
        type = "test",
        alternate = "lib/{dirname}/live/{basename}_live.ex",
        template = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
          "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
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
        alternate = "lib/{dirname}/controllers/{basename}_controller.ex",
        type = "test",
        template = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
          "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
          "end",
        },
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
        alternate = "lib/{dirname}/channels/{basename}_channel.ex",
        type = "test",
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
        alternate = "test/{}_test.exs",
        type = "source",
        template = { "defmodule {camelcase|capitalize|dot} do", "end" },
      },
      ["test/*_test.exs"] = {
        alternate = "lib/{}.ex",
        type = "test",
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
end
return M
