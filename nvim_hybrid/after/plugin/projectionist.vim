let g:projectionist_heuristics = {
                  \  'mix.exs': {
                  \    "lib/**/views/*_view.ex": {
                  \      "type": "view",
                  \      "alternate": "test/{dirname}/views/{basename}_view_test.exs",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
                  \        "  use {dirname|camelcase|capitalize}, :view",
                  \        "end"
                  \      ]
                  \    },
                  \    "test/**/views/*_view_test.exs": {
                  \      "alternate": "lib/{dirname}/views/{basename}_view.ex",
                  \      "type": "test",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
                  \        "  use ExUnit.Case, async: true",
                  \        "",
                  \        "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
                  \        "end"
                  \      ]
                  \    },
                  \    "lib/**/live/*_live.ex": {
                  \      "type": "live",
                  \      "alternate": "test/{dirname}/views/{basename}_live_test.exs",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
                  \        "  use {dirname|camelcase|capitalize}, :live_view",
                  \        "end"
                  \      ]
                  \    },
                  \    "test/**/live/*_live_test.exs": {
                  \      "alternate": "lib/{dirname}/live/{basename}_live.ex",
                  \      "type": "test",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
                  \        "  use ExUnit.Case, async: true",
                  \        "",
                  \        "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
                  \        "end"
                  \      ]
                  \    },
                  \    "lib/**/controllers/*_controller.ex": {
                  \      "type": "controller",
                  \      "alternate": "test/{dirname}/controllers/{basename}_controller_test.exs",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Controller do",
                  \        "  use {dirname|camelcase|capitalize}, :controller",
                  \        "end"
                  \      ]
                  \    },
                  \    "test/**/controllers/*_controller_test.exs": {
                  \      "alternate": "lib/{dirname}/controllers/{basename}_controller.ex",
                  \      "type": "test",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ControllerTest do",
                  \        "  use {dirname|camelcase|capitalize}.ConnCase, async: true",
                  \        "end"
                  \      ]
                  \    },
                  \    "lib/**/channels/*_channel.ex": {
                  \      "type": "channel",
                  \      "alternate": "test/{dirname}/channels/{basename}_channel_test.exs",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel do",
                  \        "  use {dirname|camelcase|capitalize}, :channel",
                  \        "end"
                  \      ]
                  \    },
                  \    "test/**/channels/*_channel_test.exs": {
                  \      "alternate": "lib/{dirname}/channels/{basename}_channel.ex",
                  \      "type": "test",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ChannelTest do",
                  \        "  use {dirname|camelcase|capitalize}.ChannelCase, async: true",
                  \        "",
                  \        "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Channel",
                  \        "end"
                  \      ]
                  \    },
                  \    "test/**/features/*_test.exs": {
                  \      "type": "feature",
                  \      "template": [
                  \        "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Test do",
                  \        "  use {dirname|camelcase|capitalize}.FeatureCase, async: true",
                  \        "end"
                  \      ]
                  \    },
                  \    "lib/*.ex": {
                  \      "alternate": "test/{}_test.exs",
                  \      "type": "src",
                  \      "template": ["defmodule {camelcase|capitalize|dot} do", "end"]
                  \    },
                  \    "test/*_test.exs": {
                  \      "alternate": "lib/{}.ex",
                  \      "type": "test",
                  \      "template": [
                  \        "defmodule {camelcase|capitalize|dot}Test do",
                  \        "  use ExUnit.Case, async: true",
                  \        "",
                  \        "  alias {camelcase|capitalize|dot}",
                  \        "end"
                  \      ]
                  \    },
                  \    "mix.exs": { "type": "mix" },
                  \    "config/*.exs": { "type": "config" }
                  \  },
                  \  'package.json': {
                  \    '*.js': {
                  \      'alternate': [
                  \        '{dirname}/{basename}.test.js',
                  \        '{dirname}/__tests__/{basename}.test.js',
                  \      ],
                  \      'type': 'source',
                  \      'make': 'yarn',
                  \    },
                  \    '*.test.js': {
                  \      'alternate': [
                  \        '{dirname}/{basename}.js',
                  \        '{dirname}/../{basename}.js',
                  \      ],
                  \      'type': 'test',
                  \    },
                  \    '*.ts': {
                  \      'alternate': [
                  \        '{dirname}/{basename}.test.ts',
                  \        '{dirname}/{basename}.test.tsx',
                  \        '{dirname}/__tests__/{basename}.test.ts',
                  \        '{dirname}/__tests__/{basename}.test.tsx',
                  \      ],
                  \      'type': 'source',
                  \    },
                  \    '*.test.ts': {
                  \      'alternate': [
                  \        '{dirname}/{basename}.ts',
                  \        '{dirname}/{basename}.tsx',
                  \        '{dirname}/../{basename}.ts',
                  \        '{dirname}/../{basename}.tsx',
                  \      ],
                  \      'type': 'test',
                  \    },
                  \    '*.tsx': {
                  \      'alternate': [
                  \        '{dirname}/{basename}.test.ts',
                  \        '{dirname}/{basename}.test.tsx',
                  \        '{dirname}/__tests__/{basename}.test.ts',
                  \        '{dirname}/__tests__/{basename}.test.tsx',
                  \      ],
                  \      'type': 'source',
                  \    },
                  \    '*.test.tsx': {
                  \      'alternate': [
                  \        '{dirname}/{basename}.ts',
                  \        '{dirname}/{basename}.tsx',
                  \        '{dirname}/../{basename}.ts',
                  \        '{dirname}/../{basename}.tsx',
                  \      ],
                  \      'type': 'test',
                  \    },
                  \    'package.json': { 'type': 'package' }
                  \  }
                  \}
