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

  Snacks = require("snacks")
  local function walk_in_codediff(picker, item)
    picker:close()
    if item.commit then
      local current_commit = item.commit

      vim.fn.setreg("+", current_commit)
      vim.notify("Copied: " .. current_commit)
      -- get parent / previous commit
      local parent_commit = vim.trim(vim.fn.system("git rev-parse --short " .. current_commit .. "^"))
      parent_commit = parent_commit:match("[a-f0-9]+")
      -- Check if command failed (e.g., Initial commit has no parent)
      if vim.v.shell_error ~= 0 then
        vim.notify("Cannot find parent (Root commit?)", vim.log.levels.WARN)
        parent_commit = ""
      end
      local cmd = string.format("CodeDiff %s %s", parent_commit, current_commit)
      vim.notify("Diffing: " .. parent_commit .. " -> " .. current_commit)
      vim.cmd(cmd)
    end
  end

  local function git_pickaxe(opts)
    opts = opts or {}
    local is_global = opts.global or false
    local current_file = vim.api.nvim_buf_get_name(0)
    -- Force global if current buffer is invalid
    if not is_global and (current_file == "" or current_file == nil) then
      vim.notify("Buffer is not a file, switching to global search", vim.log.levels.WARN)
      is_global = true
    end

    local title_scope = is_global and "Global" or vim.fn.fnamemodify(current_file, ":t")
    vim.ui.input({ prompt = "Git Search (-G) in " .. title_scope .. ": " }, function(query)
      if not query or query == "" then return end

      -- set keyword highlight within Snacks.picker
      vim.fn.setreg("/", query)
      local old_hl = vim.opt.hlsearch
      vim.opt.hlsearch = true

      local args = {
        "log",
        "-G" .. query,
        "-i",
        "--pretty=format:%C(yellow)%h%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset",
        "--abbrev-commit",
        "--date=short",
      }

      if not is_global then
        table.insert(args, "--")
        table.insert(args, current_file)
      end

      Snacks.picker({
        title = 'Git Log: "' .. query .. '" (' .. title_scope .. ")",
        finder = "proc",
        cmd = "git",
        args = args,

        transform = function(item)
          local clean_text = item.text:gsub("\27%[[0-9;]*m", "")
          local hash = clean_text:match("^%S+")
          if hash then
            item.commit = hash
            if not is_global then item.file = current_file end
          end
          return item
        end,

        preview = "git_show",
        confirm = walk_in_codediff,
        format = "text",

        on_close = function()
          -- remove keyword highlight
          vim.opt.hlsearch = old_hl
          vim.cmd("noh")
        end,
      })
    end)
  end

  return {
    {
      "dmtrKovalenko/fff.nvim",
      lazy = false, -- make fff initialize on startup
      pin = true,
      commit = "65aeacf9e2c663c9af2b1003727aa25acac96db4",
      -- build = function() require("fff.download").download_or_build_binary() end,
      build = "cargo build --release",
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
        image = {
          doc = {
            enabled = true,
            inline = false, -- Don't render inline; use float on CursorHold instead
            float = true, -- Show image in floating window when cursor moves to image
          },
          -- Include common image directories + our vault's assets folder
          img_dirs = { "img", "images", "assets", "static", "public", "media", "attachments", "_attachments" },
          -- Resolve obsidian wikilink images (e.g., ![[image.png]])
          -- Checks vault's assets folder when image isn't found relative to file
          resolve = function(file, src)
            local vault = vim.env.NOTES_HOME
            if not vault then return nil end

            -- If src is just a filename (wikilink style), check vault's assets folder
            if not src:find("/") then
              local asset_path = vault .. "/assets/" .. src
              if vim.fn.filereadable(asset_path) == 1 then return asset_path end
            end
            return nil -- fall back to default resolution
          end,
        },
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
                ["<C-.>"] = { "toggle_hidden", mode = { "i", "n" } },
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
          "<leader>fg",
          mode = "n",
          -- function() require("snacks").picker.grep() end,
          function() require("plugins.snacks-multi-grep").multi_grep() end,
          desc = "live multi-grep",
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

        -- Keymaps
        vim.keymap.set(
          "n",
          "<leader>hs",
          function() git_pickaxe({ global = false }) end,
          { desc = "Git Search (Buffer)" }
        )

        vim.keymap.set(
          "n",
          "<leader>gs",
          function() git_pickaxe({ global = true }) end,
          { desc = "Git Search (Global)" }
        )

        vim.keymap.set(
          { "n", "t" },
          "<leader>hl",
          function()
            Snacks.picker.git_log_file({
              confirm = walk_in_codediff,
            })
          end,
          { desc = "find_git_log_file" }
        )

        vim.keymap.set(
          { "n", "t" },
          "<leader>gl",
          function()
            Snacks.picker.git_log({
              confirm = walk_in_codediff,
            })
          end,
          { desc = "find_git_log" }
        )
      end,
    },
  }
end
