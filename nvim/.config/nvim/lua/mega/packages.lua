return {
  activate = function()
    mega.inspect("activating packages.lua..")

    local exists = pcall(vim.cmd, [[packadd paq-nvim]])
    local repo_url = "https://github.com/savq/paq-nvim"
    local install_path = string.format("%s/site/pack/paqs/opt/", vim.fn.stdpath("data"))
    -- ~/.local/share/nvim/site/pack/paq/opt/paq-nvim/

    -- clone paq-nvim if we haven't already..
    if not exists or vim.fn.empty(vim.fn.glob(install_path)) > 0 then
      if vim.fn.input("-> download paq-nvim? [yn] -> ") ~= "y" then
        return
      end

      vim.fn.mkdir(install_path, "p")

      print("-> downloading paq-nvim...")
      vim.fn.system(string.format("git clone %s %s/%s", repo_url, install_path, "paq-nvim"))

      vim.cmd([[packadd paq-nvim]])

      print("-> paq-nvim installed.")
      return
    end

    vim.cmd([[packadd paq-nvim]])

    local Paq = require("paq-nvim")
    local paq = Paq.paq

    -- (paq-nvim) --
    paq {"savq/paq-nvim", opt = true}
    local plenary_exists, plenary = pcall(require, "plenary.reload")
    if plenary_exists then
      plenary.reload_module("paq-nvim")
    end

    -- (ui, interface) --
    paq "trevordmiller/nova-vim"
    paq "norcalli/nvim-colorizer.lua"
    paq "dm1try/golden_size"
    paq "ryanoasis/vim-devicons"
    paq "junegunn/rainbow_parentheses.vim"
    paq "glepnir/galaxyline.nvim"
    paq {"kyazdani42/nvim-web-devicons", opt = true}

    -- (lsp, completion, diagnostics, snippets, treesitter) --
    paq "neovim/nvim-lspconfig"
    paq "nvim-lua/completion-nvim"
    paq "nvim-lua/lsp_extensions.nvim"
    paq "nvim-treesitter/nvim-treesitter"
    paq "nvim-lua/plenary.nvim"
    paq "steelsojka/completion-buffers"
    paq "hrsh7th/vim-vsnip"
    paq "hrsh7th/vim-vsnip-integ"
    paq "RRethy/vim-illuminate"

    -- (file navigation) --
    paq {"junegunn/fzf", hook = vim.fn["fzf#install"]}
    paq "junegunn/fzf.vim"
    -- paq "ojroques/nvim-lspfuzzy"
    paq "justinmk/vim-sneak"
    -- paq "unblevable/quick-scope"

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
    paq {"nelstrom/vim-textobj-rubyblock"} -- ruby block text object (ar/ir)
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

    -- (git, vcs, et al) --
    paq "tpope/vim-fugitive"
    paq {"keith/gist.vim", hook = "!chmod -HR 0600 ~/.netrc"}
    paq "mattn/webapi-vim"
    paq "rhysd/conflict-marker.vim"
    paq "itchyny/vim-gitbranch"
    paq {"rhysd/git-messenger.vim"}
    paq {"lewis6991/gitsigns.nvim"}

    -- (development, writing, et al) --
    paq "tpope/vim-projectionist" -- projectionist.vim
    paq "janko/vim-test" -- test.vim
    paq "tpope/vim-ragtag" -- ragtag.vim
    paq "axvr/zepl.vim"
    paq "rizzatti/dash.vim"
    paq "skywind3000/vim-quickui"
    paq "sgur/vim-editorconfig"
    paq "zenbro/mirror.vim"
    paq "metakirby5/codi.vim"
    paq "junegunn/goyo.vim"
    paq "junegunn/limelight.vim"
    paq {"iamcco/markdown-preview.nvim", hook = vim.fn["mkdp#util#install"]}

    -- (the rest...) --
    paq "wsdjeg/vim-fetch" -- vim path/to/file.ext:12:3
    paq {"Raimondi/delimitMate"}
    paq "tpope/vim-endwise"
    -- paq {"rstacruz/vim-closer"}
    paq "tpope/vim-eunuch"
    paq "tpope/vim-abolish"
    paq "tpope/vim-rhubarb"
    paq "tpope/vim-repeat"
    paq "tpope/vim-surround"
    paq "tpope/vim-commentary"
    paq "tpope/vim-unimpaired"
    paq "EinfachToll/DidYouMean"
    paq "jordwalke/VimAutoMakeDirectory"
    paq "ConradIrwin/vim-bracketed-paste"
    paq "sickill/vim-pasta"
    -- :Messages <- view messages in quickfix list
    -- :Verbose  <- view verbose output in preview window.
    -- :Time     <- measure how long it takes to run some stuff.
    paq "tpope/vim-scriptease"
    paq "christoomey/vim-tmux-navigator"
    paq "tmux-plugins/vim-tmux-focus-events"
    paq "christoomey/vim-tmux-runner"
    paq "wellle/visual-split.vim"
    paq "romainl/vim-cool"

    -- (langs, syntax, et al) --
    paq "tpope/vim-rails"
    paq "gleam-lang/gleam.vim"
    paq "vim-erlang/vim-erlang-runtime"
    -- paq "Zaptic/elm-vim"
    paq "antew/vim-elm-analyse"
    paq "elixir-lang/vim-elixir"
    paq "avdgaag/vim-phoenix"
    paq "lucidstack/hex.vim"
    paq "neoclide/jsonc.vim"
    paq "gerrard00/vim-mocha-only"
    paq "plasticboy/vim-markdown"
    paq "florentc/vim-tla"
    paq "euclidianace/betterlua.vim"
    paq "andrejlevkovitch/vim-lua-format"
    paq "yyq123/vim-syntax-logfile"
    paq "jparise/vim-graphql"
    paq "darfink/vim-plist"
    paq "sheerun/vim-polyglot"

    local filename = vim.api.nvim_buf_get_name(0)
    if string.match(filename, "packages.lua") == "packages.lua" then
      Paq.update()
      Paq.install()
    -- vim.cmd([[packloadall!]])
    end
  end
}
