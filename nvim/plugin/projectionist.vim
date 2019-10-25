let g:projectionist_heuristics = {
      \  'mix.exs': {
      \    'lib/*.ex': {
      \      'type': 'src',
      \      'alternate': 'test/{}_test.exs',
      \    },
      \    'test/*_test.exs': {
      \      'type': 'test',
      \      'alternate': 'lib/{}.ex',
      \    },
      \    "mix.exs": {
      \      "type": "mix"
      \    },
      \    "config/config.exs": {
      \      "type": "config"
      \    }
      \  }
      \}
