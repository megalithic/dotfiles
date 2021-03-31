--NOTE: Packages are in the runtimepath, this file is only loaded for updates.
mega.inspect("activating packages.lua..")

vim.cmd([[packadd paq-nvim]])
package.loaded["paq-nvim"] = nil -- Refresh package list

-- local plenary_exists, plenary = pcall(require, "plenary.reload")
-- if plenary_exists then
--   plenary.reload_module("paq-nvim")
-- end

local paq_exists, Paq = pcall(require, "paq-nvim")
if paq_exists then
  local paq = Paq.paq

  -- (local/development packages) --
  --    -- located in: ~/.local/share/nvim/site/pack/local
  -- paq {"megalithic/zk.nvim"}
  -- paq {"megalithic/lexima.vim"}
  -- paq {"megalithic/nvim-fzf-commands"}

  -- (paq-nvim) --
  paq {"savq/paq-nvim", opt = true}
  paq {"tweekmonster/startuptime.vim"}
  -- :StartupTime 100 -- -u ~/foo.vim -i NONE -- ~/foo.vim

  -- (ui, interface) --
  -- paq {"trevordmiller/nova-vim"}
  paq {"sainnhe/everforest"}
  -- paq {"cocopon/inspecthi.vim", opt=true}
  paq {"norcalli/nvim-colorizer.lua"}
  paq {"dm1try/golden_size"}
  paq {"junegunn/rainbow_parentheses.vim"}
  paq {"ryanoasis/vim-devicons"}
  paq {"hoob3rt/lualine.nvim"}
  paq {"danilamihailov/beacon.nvim"}
  paq {"antoinemadec/FixCursorHold.nvim"}
  paq {"psliwka/vim-smoothie"}
  paq {"lukas-reineke/indent-blankline.nvim", branch = "lua"}

  -- (lsp, completion, diagnostics, snippets, treesitter) --
  paq {"neovim/nvim-lspconfig"}
  paq {"nvim-lua/plenary.nvim"}
  paq {"nvim-lua/popup.nvim"}
  paq {"hrsh7th/nvim-compe"}
  paq {"onsails/lspkind-nvim"}
  paq {"hrsh7th/vim-vsnip"}
  paq {"hrsh7th/vim-vsnip-integ"}
  paq {"nvim-lua/lsp-status.nvim"}
  paq {"nvim-lua/lsp_extensions.nvim"}
  paq {"glepnir/lspsaga.nvim"}
  paq {
    "nvim-treesitter/nvim-treesitter"
    -- run = function()
    --   vim.api.nvim_command("TSUpdate")
    -- end
  }
  paq {
    "nvim-treesitter/completion-treesitter"
    -- run = function()
    --   vim.api.nvim_command("TSUpdate")
    -- end
  }
  paq {"nvim-treesitter/nvim-treesitter-textobjects"}
  -- paq {"nvim-treesitter/nvim-treesitter-refactor"}

  -- (file navigation) --
  paq {"junegunn/fzf", run = vim.fn["fzf#install"]}
  paq {"junegunn/fzf.vim"}
  paq {"vijaymarupudi/nvim-fzf"}
  paq {"ojroques/nvim-lspfuzzy"}
  paq {"nvim-telescope/telescope.nvim"}
  paq {"unblevable/quick-scope"}
  -- https://github.com/elianiva/dotfiles/blob/master/nvim/.config/nvim/lua/modules/_mappings.lua
  -- paq {"tjdevries/astronauta.nvim"}

  -- (text objects) --
  paq {"tpope/vim-rsi"}
  paq {"kana/vim-operator-user"}
  -- -- provide ai and ii for indent blocks
  -- -- provide al and il for current line
  -- -- provide a_ and i_ for underscores
  -- -- provide a- and i-
  paq {"kana/vim-textobj-user"} -- https://github.com/kana/vim-textobj-user/wiki
  paq {"kana/vim-textobj-function"} -- function text object (af/if)
  paq {"kana/vim-textobj-indent"} -- for indent level (ai/ii)
  paq {"kana/vim-textobj-line"} -- for current line (al/il)
  paq {"andyl/vim-textobj-elixir"} -- elixir block text object (ae/ie)
  paq {"glts/vim-textobj-comment"} -- comment text object (ac/ic)
  paq {"michaeljsmith/vim-indent-object"}
  paq {"machakann/vim-textobj-delimited"} -- - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
  paq {"gilligan/textobj-lastpaste"} -- - P     for last paste
  paq {"mattn/vim-textobj-url"} -- - u     for url
  paq {"rhysd/vim-textobj-anyblock"} -- - '', \"\", (), {}, [], <>
  paq {"arthurxavierx/vim-caser"} -- https://github.com/arthurxavierx/vim-caser#usage
  paq {"Julian/vim-textobj-variable-segment"} -- variable parts (av/iv)
  paq {"sgur/vim-textobj-parameter"} -- function parameters (a,/i,)
  paq {"wellle/targets.vim"} -- improved targets line cin) next parens) https://github.com/wellle/targets.vim/blob/master/cheatsheet.md
  paq {"junegunn/vim-easy-align"}
  -- https://github.com/AckslD/nvim-revJ.lua

  -- (git, vcs, et al) --
  paq {"tpope/vim-fugitive"}
  paq {"keith/gist.vim", run = "!chmod -HR 0600 ~/.netrc"}
  paq {"mattn/webapi-vim"}
  paq {"rhysd/conflict-marker.vim"}
  paq {"itchyny/vim-gitbranch"}
  paq {"rhysd/git-messenger.vim"}
  paq {"lewis6991/gitsigns.nvim"}
  paq {"drzel/vim-repo-edit"} -- https://github.com/drzel/vim-repo-edit#usage

  -- (development, writing, et al) --
  paq {"tpope/vim-projectionist"}
  paq {"janko/vim-test"}
  paq {"tpope/vim-ragtag"}
  paq {"rizzatti/dash.vim"}
  paq {"skywind3000/vim-quickui"}
  paq {"sgur/vim-editorconfig"}
  paq {"zenbro/mirror.vim", opt = true}
  paq {"junegunn/goyo.vim", opt = true}
  paq {"junegunn/limelight.vim", opt = true}
  paq {"reedes/vim-pencil", opt = true}
  paq {"iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"]}
  -- paq {"SidOfc/mkdx"}
  -- paq {"reedes/vim-wordy", opt = true}
  -- paq {"reedes/vim-lexical", opt = true}
  -- paq {"sedm0784/vim-you-autocorrect"}
  -- paq {
  --   "npxbr/glow.nvim",
  --   run = function()
  --     vim.api.nvim_command("GlowInstall")
  --   end
  -- }

  -- (the rest...) --
  paq {"ojroques/vim-oscyank"}
  paq {"wsdjeg/vim-fetch"} -- vim path/to/file.ext:12:3
  paq {"farmergreg/vim-lastplace"}
  -- paq {"blackCauldron7/surround.nvim"}
  paq {"andymass/vim-matchup"}
  -- paq {"windwp/nvim-autopairs"} -- https://github.com/windwp/nvim-autopairs#using-nvim-compe
  paq {"alvan/vim-closetag"}
  -- paq {"Raimondi/delimitMate"}
  -- paq {"tpope/vim-endwise"}
  -- paq {"rstacruz/vim-closer"} -- broke: has conflicting tags `closer`
  paq {"b3nj5m1n/kommentary"} -- broke: issues with multiline in lua
  -- paq {"terrortylor/nvim-comment"}
  -- paq {"tpope/vim-commentary"}
  paq {"tpope/vim-eunuch"}
  paq {"tpope/vim-abolish"}
  paq {"tpope/vim-rhubarb"}
  paq {"tpope/vim-repeat"}
  paq {"tpope/vim-surround"}
  paq {"tpope/vim-unimpaired"}
  paq {"EinfachToll/DidYouMean"}
  paq {"jordwalke/VimAutoMakeDirectory"}
  paq {"ConradIrwin/vim-bracketed-paste"}
  paq {"sickill/vim-pasta"}
  -- :Messages <- view messages in quickfix list
  -- :Verbose  <- view verbose output in preview window.
  -- :Time     <- measure how long it takes to run some stuff.
  paq {"tpope/vim-scriptease"}
  paq {"christoomey/vim-tmux-navigator"} -- https://github.com/knubie/vim-kitty-navigator analog
  -- paq {"tmux-plugins/vim-tmux-focus-events"}
  paq {"christoomey/vim-tmux-runner"}
  -- paq {"wellle/visual-split.vim"}
  paq {"junegunn/vim-slash"}
  -- paq {"junegunn/vim-peekaboo"}
  paq {"gennaro-tedesco/nvim-peekup"} -- peek into the vim registers in floating window

  -- https://github.com/awesome-streamers/awesome-streamerrc/blob/master/ThePrimeagen/plugin/firenvim.vim
  paq {
    "glacambre/firenvim",
    run = function()
      vim.fn["firenvim#install"](777)
    end
  }

  -- (langs, syntax, et al) --
  paq {"tpope/vim-rails"}
  paq {"gleam-lang/gleam.vim"}
  paq {"vim-erlang/vim-erlang-runtime"}
  paq {"antew/vim-elm-analyse"}
  paq {"elixir-lang/vim-elixir"}
  paq {"avdgaag/vim-phoenix"}
  paq {"lucidstack/hex.vim"}
  paq {"neoclide/jsonc.vim"}
  -- paq {"gerrard00/vim-mocha-only"}
  paq {"plasticboy/vim-markdown"}
  -- paq {"florentc/vim-tla"}
  paq {"euclidianace/betterlua.vim"}
  -- paq {"TravonteD/luajob"}
  paq {"andrejlevkovitch/vim-lua-format"}
  paq {"yyq123/vim-syntax-logfile"}
  paq {"jparise/vim-graphql"}
  paq {"darfink/vim-plist"}

  paq {"sheerun/vim-polyglot"}

  mega.augroup_cmds(
    "mega.paq",
    {
      {
        events = {"BufWritePost"},
        targets = {"packages.lua"},
        command = [[luafile %]]
      }
    }
  )
end
