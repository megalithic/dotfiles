return {
  -- fff.nvim - Fast file finder (prebuilt binary via download)
  {
    "dmtrKovalenko/fff.nvim",
    lazy = false,
    -- pin = true,
    build = function() require("fff.download").download_or_build_binary() end,
    opts = {
      max_results = 400,
      max_threads = 8,
    },
  },

  -- fff-snacks.nvim - Snacks picker integration for fff (merged fork)
  -- {
  --   "megalithic/fff-snacks.nvim",
  --   dependencies = { "dmtrKovalenko/fff.nvim", "folke/snacks.nvim" },
  --   cmd = { "FFFSnacks", "FFFSnacksGrep" },
  --   keys = {
  --     { "<leader>ff", "<cmd>FFFSnacks<cr>", desc = "pick: files" },
  --     { "<leader>a", "<cmd>FFFSnacksGrep<cr>", desc = "pick: live grep" },
  --     { "<leader>A", "<cmd>FFFSnacksGrepWord<cr>", desc = "pick: word grep", mode = { "n", "x" } },
  --   },
  --   opts = function()
  --     local layouts = require("plugins.snacks.layouts")
  --     return {
  --       layout = function() return layouts.smart_layout() end,
  --       git_icons = {
  --         added = " ",
  --         modified = " ",
  --         untracked = "󰎔 ",
  --         deleted = " ",
  --         ignored = " ",
  --         renamed = " ",
  --         clean = "  ",
  --       },
  --       frecency_indicators = {
  --         enabled = true,
  --         hot = "🔥",
  --         warm = "⚡",
  --         medium = "●",
  --         cold = "○",
  --       },
  --     }
  --   end,
  -- },

  {
    "megalithic/fff-snacks.nvim",
    branch = "main",
    -- "madmaxieee/fff-snacks.nvim",
    lazy = false, -- lazy loaded by design
    opts = {
      -- Snacks picker config for file picker
      -- find_files = {},

      -- Snacks picker config for grep picker
      -- live_grep = {
      --   grep_mode = { "fuzzy", "plain", "regex" }, -- order of modes to cycle
      -- },

      -- Keybindings
      keys = {
        cycle_grep_mode = "<c-y>", -- cycle plain/regex/fuzzy
        cycle_picker = "<c-r>", -- toggle files ↔ grep
      },

      -- Titles when toggling
      titles = {
        files_from_grep = "FFFiles (from grep)",
        grep_from_files = "FFFGrep (from files)",
      },

      -- Scoping behavior
      scoping = {
        warn_threshold = nil, -- warn if scoping > N files
        disable_threshold = nil, -- disable scoping if > N files
      },

      -- Jump behavior
      jump = {
        reuse_win = true, -- focus existing window if buffer open
      },
    },
    keys = {
      {
        "<leader>ff",
        function() require("fff-snacks").find_files() end,
        desc = "FFF find files",
      },
      {
        "<leader>A",
        function() require("fff-snacks").grep_word() end,
        desc = "FFF grep word",
        mode = { "n", "v" },
      },
      {
        "<leader>a",
        function()
          require("fff-snacks").live_grep({
            grep_mode = { "fuzzy", "plain", "regex" },
          })
        end,
        desc = "FFF live grep (fuzzy)",
      },
    },
  },

  -- Main snacks.nvim config
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    opts = function()
      local layouts = require("plugins.snacks.layouts")

      ---@type snacks.Config
      return {
        -- Feature toggles
        bigfile = { enabled = true },
        dashboard = { enabled = false },
        explorer = { enabled = false },
        indent = { enabled = false },
        notifier = {
          enabled = true,
          top_down = false, -- bottom-up (notifications from bottom)
          style = "minimal", -- no border, just icon + message
          margin = { top = 0, right = 1, bottom = 1 },
          width = { min = 30, max = 0.4 },
          height = { min = 1, max = 0.3 },
          timeout = 3000,
        },
        quickfile = { enabled = true },
        scroll = { enabled = false },
        statuscolumn = { enabled = false },
        terminal = { enabled = true },
        words = { enabled = true },

        -- Input styling
        input = {
          icon = "",
          win = {
            relative = "editor",
            backdrop = 60,
            title_pos = "left",
            width = 50,
            row = math.ceil(vim.o.lines / 2) - 3,
          },
        },

        -- Picker config
        picker = {
          enabled = true,
          ui_select = true,

          -- Default layout
          layout = function() return layouts.smart_layout() end,

          -- Register static layout presets
          layouts = layouts.presets,

          -- Matcher settings
          matcher = {
            cwd_bonus = true,
            frecency = true,
            history_bonus = true,
          },

          -- Formatters
          formatters = {
            file = {
              filename_first = true,
              truncate = 80,
            },
          },

          -- Previewers
          previewers = {
            file = {
              max_size = 10 * 1024 * 1024, -- 10MB
            },
            git = {
              builtin = false, -- Use external git with delta
            },
            diff = {
              builtin = false,
              cmd = { "delta", "--width", vim.o.columns },
            },
          },

          -- Source-specific configs
          sources = {
            -- REF: https://github.com/chrisgrieser/.config/blob/main/nvim/lua/plugin-specs/snacks-picker.lua
            -- explorer = {
            --   replace_netrw = true,
            --   git_status = true,
            --   hidden = true,
            --   ignored = true,
            --   jump = { close = true },
            --   win = {
            --     list = {
            --       keys = {
            --         ["]c"] = "explorer_git_next",
            --         ["[c"] = "explorer_git_prev",
            --         ["<c-t>"] = { "tab", mode = { "n", "i" } },
            --       },
            --     },
            --   },
            --   icons = {
            --     tree = {
            --       vertical = "  ",
            --       middle = "  ",
            --       last = "  ",
            --     },
            --   },
            -- },
            buffers = {
              current = false,
            },
            files = {
              hidden = true,
              follow = true,
              args = {
                -- these are *always* ignored, even if `toggle_ignored` is switched
                ("--ignore-file=" .. vim.env.HOME .. "/.ignore"),
              },
            },
            undo = {
              win = {
                input = {
                  keys = {
                    -- <CR>: restores the selected undo point
                    ["<D-c>"] = { "yank_add", mode = "i" },
                    ["<D-d>"] = { "yank_del", mode = "i" },
                  },
                },
              },
              layout = "big_preview",
            },
            registers = {
              transform = function(item) return item.label:find("[1-9]") ~= nil end, -- only numbered
              confirm = { "yank", "close" },
            },
            explorer = {
              layout = { preset = "small_no_preview", layout = { height = 0.85 } },
              jump = { close = true },
              win = {
                list = {
                  keys = {
                    -- consistent with Finder vim mode bindings
                    ["<D-up>"] = "explorer_up",
                    ["h"] = "explorer_close", -- go up folder
                    ["l"] = "confirm", -- enter folder / open file
                    ["zz"] = "explorer_close_all",
                    ["y"] = "explorer_copy",
                    ["n"] = "explorer_add",
                    ["d"] = "explorer_del",
                    ["m"] = "explorer_move",
                    ["o"] = "explorer_open", -- open with system application
                    ["<CR>"] = "explorer_rename",
                    ["-"] = "focus_input", -- i.e. search
                    ["<C-CR>"] = { "cycle_win", mode = "i" },

                    -- consistent with `gh` for next hunk and `ge` for next diagnostic
                    ["gh"] = "explorer_git_next",
                    ["gH"] = "explorer_git_prev",
                    ["ge"] = "explorer_diagnostic_next",
                    ["gE"] = "explorer_diagnostic_prev",
                  },
                },
              },
            },
            recent = { layout = "small_no_preview" },
            grep = {
              regex = false, -- use fixed strings by default
              cmd = "rg",
              args = {
                "--sortr=modified", -- sort by recency, slight performance impact
                "--no-config",
                -- these are *always* ignored, even if `toggle_ignored` is switched
                ("--ignore-file=" .. vim.env.HOME .. "/.config/ripgrep/ignore"),
              },
            },
            help = {
              confirm = function(picker)
                picker:action("help")
                vim.cmd.only() -- so help is full window
              end,
            },
            keymaps = {
              -- open keymap definition
              confirm = function(picker, item)
                if not item.file then return end
                picker:close()
                local lnum = item.pos[1]
                vim.cmd(("edit +%d %s"):format(lnum, item.file))
              end,
              layout = { preset = "big_preview", hidden = { "preview" } },
            },
            lines = {},
            lsp_references = {
              pattern = "!import !default", -- Exclude imports/default exports
            },
            lsp_symbols = {
              layout = "sidebar",
              finder = "lsp_symbols",
              format = "lsp_symbol",
              hierarchy = true,
              filter = {
                default = true,
                markdown = true,
                help = true,
              },
            },
            lsp_workspace_symbols = {},
            diagnostics = {},
            diagnostics_buffer = {},
            git_status = {
              preview = "git_status",
              layout = { preset = "sidebar_no_input" },
              win = {
                list = { keys = { ["<Space>"] = "git_stage" } },
                preview = { keys = { ["<Space>"] = "git_stage" } },
              },
            },
            git_diff = {
              layout = { preset = "sidebar_no_input" },
              win = {
                list = { keys = { ["<Space>"] = "git_stage" } },
                preview = { keys = { ["<Space>"] = "git_stage" } },
              },
            },
            treesitter = {
              layout = "sidebar",
              filter = { markdown = { "Field" } }, -- requires `queries/markdown/locals.scm`
            },
          },

          -- Window keymaps
          win = {
            preview = {
              wo = { wrap = false },
            },
            input = {
              keys = {
                -- Navigation
                ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
                ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
                ["<c-f>"] = { "flash", mode = { "n", "i" } },

                -- Actions
                -- ["<CR>"] = { "confirm", mode = { "i", "n" } },
                ["<CR>"] = { "edit_vsplit", mode = { "i", "n" } },
                ["<c-t>"] = { "edit_tab", mode = { "i", "n" } },
                ["<c-o>"] = { "edit", mode = { "i", "n" } },
                ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
                ["<c-s>"] = { "edit_split", mode = { "i", "n" } },

                -- Close
                ["<Esc>"] = { "close", mode = { "i", "n" } },
                ["<c-c>"] = { "cancel", mode = "i" },

                -- Toggles (chrisgrieser pattern: C-h toggles both)
                ["<c-h>"] = { { "toggle_hidden", "toggle_ignored" }, mode = { "i", "n" } }, ---@diagnostic disable-line: assign-type-mismatch
                ["<c-r>"] = { "toggle_regex", mode = { "i", "n" } },

                -- Help
                ["?"] = { "toggle_help_input", mode = { "i" } },
              },
            },
            list = {
              keys = {
                ["<c-t>"] = "edit_tab",
                ["<c-o>"] = "edit",
                ["<c-v>"] = "edit_vsplit",
                ["<c-s>"] = "edit_split",
                ["q"] = "close",
                ["<Esc>"] = "close",
                ["?"] = "toggle_help_list",
              },
            },
          },

          -- Icons
          icons = {
            ui = { selected = "󰒆" },
            git = {
              staged = "󰐖",
              added = "󰎔",
              modified = "󰄯",
              renamed = "󰏬",
            },
          },

          -- Prompt
          prompt = "  ",
        },

        -- Styles
        styles = {
          input = {
            relative = "cursor",
            row = 1,
          },
          notification_history = {
            border = "rounded",
          },
          notification = {
            border = "single",
            wo = { winblend = 0 },
          },
          zen = {
            relative = "editor",
            backdrop = { transparent = false },
          },
        },
      }
    end,

    keys = function()
      local layouts = require("plugins.snacks.layouts")
      local pickers = require("plugins.snacks.pickers")

      return {
        -- Pickers: files (<leader>ff handled by fff-snacks.nvim)
        {
          "<leader>fa",
          function()
            Snacks.picker.files({
              cmd = "fd",
              args = { "--color=never", "--hidden", "--type", "f", "--type", "l", "--no-ignore", "--exclude", ".git" },
            })
          end,
          desc = "Find all files",
        },
        { "<leader>fr", function() Snacks.picker.recent() end, desc = "Find recent" },

        -- Pickers: buffers
        { "<leader><leader>", function() Snacks.picker.buffers() end, desc = "Find buffers" },
        { "<leader>fj", function() Snacks.picker.jumps() end, desc = "Find jumps" },
        { "<leader>bj", pickers.buffer_jumps, desc = "Buffer jumps" },

        -- Pickers: grep
        -- { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
        -- { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Grep word", mode = { "n", "x" } },
        { "<leader>fl", function() Snacks.picker.lines({ layout = layouts.buffer_layout }) end, desc = "Find lines" },

        -- Pickers: LSP (goto keys gd/gr/gi/gy defined in lua/lsp/keymaps.lua)
        { "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols" },
        { "<leader>fS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace symbols" },
        { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },

        -- Pickers: git
        -- { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
        -- { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git commits" },
        -- { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git branches" },
        -- { "<leader>gd", pickers.git_diff_in_file, desc = "Git diff (file)" },
        -- { "<leader>gS", function() pickers.git_pickaxe({ global = false }) end, desc = "Git search (file)" },
        -- { "<leader>gG", function() pickers.git_pickaxe({ global = true }) end, desc = "Git search (global)" },

        -- Pickers: custom
        { "<leader>fz", pickers.file_surfer, desc = "File surfer (zoxide)" },
        { "<leader>fo", pickers.find_associated_files, desc = "Associated files" },
        { "<leader>fe", pickers.explorer, desc = "Explorer" },
        { "<leader>fb", pickers.buffers_and_recent, desc = "Buffers + recent" },

        -- Pickers: help/misc
        { "<leader>fh", function() Snacks.picker.help() end, desc = "Help" },
        { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
        { "<leader>f:", function() Snacks.picker.command_history() end, desc = "Command history" },
        { "<leader>f/", function() Snacks.picker.resume() end, desc = "Resume picker" },
        { "<leader>fu", function() Snacks.picker.undo() end, desc = "Undo history" },
        { "<leader>fc", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },

        -- Words (reference navigation)
        { "]]", function() Snacks.words.jump(vim.v.count1, true) end, desc = "Next reference" },
        { "[[", function() Snacks.words.jump(-vim.v.count1, true) end, desc = "Prev reference" },

        -- Notifier
        { "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification history" },
        { "<leader>uN", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },

        {
          "<leader>fg",
          function()
            if pickers.get_root() ~= nil then
              pickers.diff()
            else
              require("snacks").picker.git_status()
            end
          end,
          desc = "Git status",
        },
      }
    end,

    init = function()
      -- Export modules for use elsewhere
      mega.p.snacks = {
        layouts = function() return require("plugins.snacks.layouts") end,
        pickers = function() return require("plugins.snacks.pickers") end,
      }

      -- Global debug helpers
      _G.dd = function(...) Snacks.debug.inspect(...) end
      _G.bt = function() Snacks.debug.backtrace() end

      -- Pick command
      vim.api.nvim_create_user_command("Pick", function(opts)
        local source = opts.fargs[1]
        if source then
          if Snacks.picker[source] then
            Snacks.picker[source]()
          else
            vim.notify("Unknown snacks picker source: " .. source, vim.log.levels.ERROR)
          end
        else
          Snacks.picker()
        end
      end, {
        desc = "Open Snacks Picker",
        nargs = "?",
        complete = function() return vim.tbl_keys(Snacks.picker.sources) end,
      })
      vim.cmd.cabbrev("P", "Pick")
    end,
  },
}
