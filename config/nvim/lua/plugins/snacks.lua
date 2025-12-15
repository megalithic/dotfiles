if true then
  local M = {}

  local repeatable = require("config.repeatable")

  local next_ref_repeat, prev_ref_repeat = repeatable.make_repeatable_move_pair( --
    function() require("snacks").words.jump(vim.v.count1, true) end,
    function() require("snacks").words.jump(-vim.v.count1, true) end
  )
  ---Shared layout options for pickers
  ---@type snacks.picker.layout.Config
  M.shared_layout_opts = {
    preview = "main",
    layout = {
      box = "vertical",
      border = "solid",
      min_width = 50,
      min_height = 10,
      backdrop = false,
      { win = "preview", title = "{preview}", width = 0.6, border = "top" },
      { win = "input", height = 1, border = "single" },
      { win = "list", border = "none" },
    },
  }

  ---Get layout configuration for buffer-specific picker
  ---Positions picker at bottom-left of current window
  ---@return snacks.picker.layout.Config
  function M.buffer_layout()
    local win = vim.api.nvim_get_current_win()
    local win_pos = vim.api.nvim_win_get_position(win)
    local win_width = vim.api.nvim_win_get_width(win)
    local win_height = vim.api.nvim_win_get_height(win)

    local border_width = 2
    local picker_height = math.floor(0.25 * win_height)
    local col = win_pos[2]
    local row = win_pos[1] + win_height - picker_height - 1

    return vim.tbl_deep_extend("force", M.shared_layout_opts, {
      layout = {
        col = col,
        width = win_width - border_width,
        row = row,
        height = picker_height,
      },
    })
  end

  ---Get smart layout that adapts based on window width
  ---Uses centered layout for wide windows (>= 165 cols), buffer layout otherwise
  ---@return snacks.picker.layout.Config
  function M.smart_layout()
    local win = vim.api.nvim_get_current_win()
    local win_pos = vim.api.nvim_win_get_position(win)
    local win_width = vim.api.nvim_win_get_width(win)
    local win_height = vim.api.nvim_win_get_height(win)

    local picker_height = math.floor(0.45 * win_height)
    local row = win_pos[1] + win_height - picker_height - 1

    if win_width >= 165 then
      return vim.tbl_deep_extend("force", M.shared_layout_opts, {
        layout = {
          width = 0.5,
          row = row,
          height = picker_height,
        },
      })
    else
      return M.buffer_layout()
    end
  end

  return {
    {
      "dmtrKovalenko/fff.nvim",
      build = "cargo build --release",
      lazy = false, -- make fff initialize on startup
      opts = {
        max_results = 400,
        max_threads = 8,
        debug = {
          enabled = true, -- we expect your collaboration at least during the beta
          show_scores = true, -- to help us optimize the scoring system, feel free to share your scores!
        },
      },
    },

    {
      -- "madmaxieee/fff-snacks.nvim",
      -- "ahkohd/fff-snacks.nvim",
      "nikbrunner/fff-snacks.nvim",

      dependencies = {
        "dmtrKovalenko/fff.nvim",
        "folke/snacks.nvim",
      },
      cmd = "FFFSnacks",
      keys = {
        {
          "<leader>ff",
          "<cmd>FFFSnacks<cr>",
          desc = "smart fffiles",
        },
      },
      opts = {
        layout = function() return M.smart_layout() end,
        title = "smart fffiles",
        git_icons = {
          added = " ",
          modified = " ",
          untracked = "󰎔 ",
          deleted = " ",
          ignored = " ",
          renamed = " ",
          clean = "  ",
        },
      },
    },

    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        bigfile = { enabled = true },
        dashboard = { enabled = false },
        explorer = { enabled = false },
        image = { enabled = true },
        picker = {
          enabled = true,
          ui_select = true,
          formatters = {
            file = {
              filename_first = true, -- display filename before the file path
              truncate = 80,
            },
          },
          previewers = {
            file = {
              max_size = 10 * 1024 * 1024, -- 10MB
            },
            git = {
              builtin = false, -- use external git command with delta
            },
            diff = {
              builtin = false, -- use external delta command for diffs
              cmd = { "delta", "--width", vim.o.columns }, -- explicit width since PTY is disabled when piping input
            },
          },
          layout = function() return M.smart_layout() end,
          matcher = {
            -- the bonusses below, possibly require string concatenation and path normalization,
            -- so this can have a performance impact for large lists and increase memory usage
            cwd_bonus = true, -- give bonus for matching files in the cwd
            frecency = true, -- frecency bonus
            history_bonus = true,
          },
          sources = {
            explorer = {
              replace_netrw = true,
              git_status = true,
              jump = {
                close = true,
              },
              hidden = true,
              ignored = true,
              win = {
                list = {
                  keys = {
                    ["]c"] = "explorer_git_next",
                    ["[c"] = "explorer_git_prev",
                    ["<c-t>"] = { "tab", mode = { "n", "i" } },
                  },
                },
              },
              icons = {
                tree = {
                  vertical = "  ",
                  middle = "  ",
                  last = "  ",
                },
              },
            },
            buffers = {
              current = false,
            },
            files = {
              hidden = true,
            },
            recent = {},
            lines = {},
            lsp_references = {
              pattern = "!import !default", -- Exclude Imports and Default Exports
            },
            lsp_symbols = {
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
            },
            git_diff = {},
          },
          win = {
            preview = {
              wo = {
                wrap = false,
              },
            },
            input = {
              keys = {
                ["<c-t>"] = { "edit_tab", mode = { "i", "n" } },
                ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
                ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
                ["<c-f>"] = { "flash", mode = { "n", "i" } },
                ["<CR>"] = { "jump_or_split", mode = { "i", "n" } },
                ["<Esc>"] = { "close", mode = { "i" } },
                ["<C-c>"] = { "cancel", mode = "i" },
              },
            },
            list = {
              keys = {
                ["<c-t>"] = "edit_tab",
              },
            },
          },
          actions = {
            jump_or_split = function(picker, item)
              local target_wins = function()
                local targets = {}
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local buf = vim.api.nvim_win_get_buf(win)
                  local cfg = vim.api.nvim_win_get_config(win)
                  if (vim.bo[buf].buflisted and cfg.relative == "") or vim.bo[buf].ft == "snacks_dashboard" then
                    local file = vim.api.nvim_buf_get_name(buf)
                    table.insert(targets, { win = win, buf = buf, file = file })
                  end
                end
                return targets
              end
              local targets = target_wins()
              for _, targ in ipairs(targets) do
                if targ.file == item.file or vim.bo[targ.buf].ft == "snacks_dashboard" then
                  picker.opts.jump.reuse_win = true --[[Override]]
                  picker:action("jump")
                  return
                end
              end
              picker:action("vsplit")
            end,
          },
        },
        indent = { enabled = false },
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
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scroll = { enabled = false },
        statuscolumn = { enabled = false },
        words = { enabled = true },
        styles = {
          input = {
            relative = "cursor",
            row = 1,
          },
          zen = {
            relative = "editor",
            backdrop = { transparent = false },
          },
          blame_line = {
            relative = "editor",
            width = 0.65,
            height = 0.8,
            border = vim.o.winborder --[[@as "rounded"|"single"|"double"|"solid"]],
            title = " 󰆽 Git blame ",
          },
        },
      },
      keys = {
        {
          "<leader>a",
          mode = "n",
          function() require("snacks").picker.grep() end,
          -- function() require("plugins.snacks-multi-grep").multi_grep() end,
          desc = "live grep",
          -- desc = "live grep (multi)",
        },
        {
          "<leader>A",
          mode = { "n", "x", "v" },
          function() require("snacks").picker.grep_word() end,
          desc = "grep cursor/selection",
        },
        -- {
        --   "<leader>fg",
        --   function()
        --     require("snacks").picker.git_status()
        --   end,
        --   desc = "Git status",
        -- },
        {
          "<leader>fa",
          function()
            require("snacks").picker.files({
              cmd = "fd",
              args = {
                "--color=never",
                "--hidden",
                "--type",
                "f",
                "--type",
                "l",
                "--no-ignore",
                "--exclude",
                ".git",
              },
            })
          end,
          desc = "[f]ind [a]ll files",
        },
        {
          "<leader><leader>",
          function() require("snacks").picker.buffers() end,
          desc = "Find buffers",
        },
        -- {
        --   "<leader>fj",
        --   function()
        --     require("snacks").picker.jumps()
        --   end,
        --   desc = "Find jumps",
        -- },
        {
          "<leader>fh",
          function() require("snacks").picker.help() end,
          desc = "Find help",
        },
        -- {
        --   "<leader>fz",
        --   function()
        --     require("snacks").picker.lines()
        --   end,
        --   desc = "Find lines",
        -- },
        -- {
        --   "<leader>fr",
        --   function()
        --     require("snacks").picker.resume()
        --   end,
        --   desc = "Find recent files",
        -- },
        -- {
        --   "<leader>cm",
        --   function()
        --     require("snacks").picker.git_log()
        --   end,
        --   desc = "Git commits",
        -- },
        -- {
        --   "<leader>gg",
        --   function()
        --     require("snacks").picker.git_files()
        --   end,
        --   desc = "Find git files",
        -- },
        -- {
        --   "<leader>fd",
        --   function()
        --     require("snacks").picker.diagnostics()
        --   end,
        --   desc = "Find diagnostics",
        -- },
        -- {
        --   "<leader>fs",
        --   function()
        --     require("snacks").picker.lsp_symbols()
        --   end,
        --   desc = "Find document symbols",
        -- },
        -- {
        --   "<leader>ws",
        --   function()
        --     require("snacks").picker.lsp_workspace_symbols()
        --   end,
        --   desc = "Find workspace symbols",
        -- },
        -- {
        --   "<leader>fc",
        --   function()
        --     require("snacks").picker.command_history()
        --   end,
        --   desc = "Find commands",
        -- },
        {
          "<leader>fu",
          function() require("snacks").picker.undo() end,
          desc = "Find undo history",
        },
        {
          "]]",
          next_ref_repeat,
          desc = "Next Reference",
        },
        {
          "[[",
          prev_ref_repeat,
          desc = "Prev Reference",
        },
      },
      init = function()
        vim.api.nvim_create_user_command("Pick", function(opts)
          local source = opts.fargs[1]
          if source then
            if require("snacks").picker[source] then
              require("snacks").picker[source]()
            else
              vim.notify("unknown snacks picker source: " .. source, vim.log.levels.ERROR)
            end
          else
            require("snacks").picker()
          end
        end, {
          desc = "Open Snacks Picker",
          nargs = "?",
          complete = function() return vim.tbl_keys(require("snacks").picker.sources) end,
        })
        vim.cmd.cabbrev("P", "Pick")

        _G.dd = function(...) require("snacks").debug.inspect(...) end
        _G.bt = function() require("snacks").debug.backtrace() end

        -- modify certain notifications
        vim.notify = function(msg, lvl, nOpts) ---@diagnostic disable-line: duplicate-set-field intentional overwrite
          nOpts = nOpts or {}

          local ignore = (msg == "No code actions available" and vim.bo.ft == "typescript")
            or msg:find("^Client marksman quit with exit code 1 and signal 0.") -- https://github.com/artempyanykh/marksman/issues/348
            or msg:find("^Error executing vim.schedule.*/_folding_range.lua:311")
          if ignore then return end

          if msg:find("Hunk %d+ of %d+") then -- gitsigns.nvim
            nOpts.style = "minimal"
            msg = msg .. "  "
            nOpts.icon = "󰊢 "
            nOpts.id = "gitsigns"
          elseif msg:find("^%[nvim%-treesitter") then -- treesitter parser update
            nOpts.id = "treesitter-parser-update"
          end
          require("snacks").notifier(msg, lvl, nOpts)
        end
      end,
    },
  }
end
