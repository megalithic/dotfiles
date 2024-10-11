return {
  {
    -- fixes ffi error:
    -- https://github.com/Saghen/blink.cmp/issues/90#issuecomment-2407226850
    "neovim-plugin/blink.cmp",

    -- "saghen/blink.cmp",
    cond = vim.g.completer == "blink",
    lazy = false, -- lazy loading handled internally
    -- optional: provides snippets for the snippet source
    dependencies = "rafamadriz/friendly-snippets",

    -- use a release tag to download pre-built binaries
    -- version = "v0.*",
    -- version = "v0.2.1", -- REQUIRED release tag to download pre-built binaries
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    build = "cargo build --release",
    -- On musl libc based systems you need to add this flag
    -- build = 'RUSTFLAGS="-C target-feature=-crt-static" cargo build --release',

    opts = {
      highlight = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        use_nvim_cmp_as_default = true,
      },
      keymap = {
        accept = "<CR>",
        hide = "<C-e>",
        select_prev = { "<S-Tab>", "<Up>", "<C-p>" },
        select_next = { "<Tab>", "<Down>", "<C-n>" },
        scroll_documentation_down = "<C-j>",
        scroll_documentation_up = "<C-k>",
        snippet_forward = { "<Tab>", "<C-l>" },
        snippet_backward = { "<S-Tab>", "<C-h>" },
      },
      -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- adjusts spacing to ensure icons are aligned
      nerd_font_variant = "normal",

      -- experimental auto-brackets support
      accept = { auto_brackets = { enabled = true } },

      -- experimental signature help support
      trigger = {
        completion = {
          show_on_insert_on_trigger_character = false,
        },
        signature_help = { enabled = true },
      },
      windows = {
        autocomplete = {
          preselect = false,
        },
      },
      sources = {
        providers = {
          {
            { "blink.cmp.sources.lsp" },
            { "blink.cmp.sources.path" },
            {
              "blink.cmp.sources.snippets",
              keyword_length = 1,
              score_offset = -3,
              opts = {
                extended_filetypes = {
                  javascriptreact = { "javascript" },
                  eelixir = { "elixir" },
                  typescript = { "javascript" },
                  typescriptreact = {
                    "javascript",
                    "javascriptreact",
                    "typescript",
                  },
                },
                friendly_snippets = false,
              },
            },
          },
          {
            { "blink.cmp.sources.buffer", keyword_length = 2 },
          },
        },
      },
    },
  },
}
