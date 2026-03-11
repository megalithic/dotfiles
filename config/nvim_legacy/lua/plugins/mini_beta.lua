if true then
  return {}
end

---Check if buffers are unsaved and prompt to save changes, continue without saving, or cancel operation
---@param all_buffers? boolean Check all buffers, or only current. Defaults to `true`
---@return boolean proceed `true` if OK to continue with action, `false` if user cancelled
local function confirm_discard_changes(all_buffers)
  local buf_list = all_buffers == false and { 0 } or vim.api.nvim_list_bufs()
  local unsaved = vim.tbl_filter(function(buf_id)
    return vim.bo[buf_id].modified and vim.bo[buf_id].buflisted
  end, buf_list)

  if #unsaved == 0 then
    return true
  end

  for _, buf_id in ipairs(unsaved) do
    local name = vim.api.nvim_buf_get_name(buf_id)
    local result = vim.fn.confirm(
      string.format('Save changes to "%s"?', name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "Untitled"),
      "&Yes\n&No\n&Cancel",
      1,
      "Question"
    )

    if result == 1 then
      if buf_id ~= 0 then
        vim.cmd("buffer " .. buf_id)
      end
      vim.cmd("update")
    elseif result == 0 or result == 3 then
      return false
    end
  end

  return true
end

local function mini_ai_setup()
  local gen_ai_spec = require("mini.extra").gen_ai_spec
  local ts = require("mini.ai").gen_spec.treesitter
  require("mini.ai").setup({
    custom_textobjects = {
      A = ts({ a = { "@attribute.outer", "@assignment.lhs" }, i = { "@attribute.inner", "@assignment.rhs" } }),
      C = ts({ a = "@class.outer", i = "@class.inner" }),
      N = gen_ai_spec.number(),
      a = require("mini.ai").gen_spec.argument({ separator = "[,;]" }),
      c = ts({ a = "@comment.outer", i = "@comment.inner" }),
      d = gen_ai_spec.diagnostic(),
      g = gen_ai_spec.buffer(),
      k = ts({ a = "@block.outer", i = "@block.inner" }),
      m = ts({ a = "@function.outer", i = "@function.inner" }),
      o = ts({ a = { "@conditional.outer", "@loop.outer" }, i = { "@conditional.inner", "@loop.inner" } }),
      t = ts({ a = "@function.outer", i = "@function.inner" }),
    },
    n_lines = 300,
  })
end

local function mini_bracketed_setup()
  require("mini.bracketed").setup({
    indent = { suffix = "" },
  })
  vim.keymap.set(
    "n",
    "[e",
    "<cmd>lua MiniBracketed.diagnostic('backward', { severity = vim.diagnostic.severity.ERROR })<cr>",
    { desc = "Error backward" }
  )
  vim.keymap.set(
    "n",
    "]e",
    "<cmd>lua MiniBracketed.diagnostic('forward', { severity = vim.diagnostic.severity.ERROR })<cr>",
    { desc = "Error forward" }
  )
  vim.keymap.set(
    "n",
    "[E",
    "<cmd>lua MiniBracketed.diagnostic('first', { severity = vim.diagnostic.severity.ERROR })<cr>",
    { desc = "Error first" }
  )
  vim.keymap.set(
    "n",
    "]E",
    "<cmd>lua MiniBracketed.diagnostic('last', { severity = vim.diagnostic.severity.ERROR })<cr>",
    { desc = "Error last" }
  )
end

local function mini_clue_setup()
  local MiniClue = require("mini.clue")
  MiniClue.setup({
    triggers = {
      { mode = "c", keys = "<C-r>" },
      { mode = "i", keys = "<C-r>" },
      { mode = "i", keys = "<C-x>" },
      { mode = "n", keys = "'" },
      { mode = "n", keys = "<C-w>" },
      { mode = "n", keys = "<Leader>" },
      { mode = "n", keys = "[" },
      { mode = "n", keys = "]" },
      { mode = "n", keys = "`" },
      { mode = "n", keys = "g" },
      { mode = "n", keys = "s" },
      { mode = "n", keys = "z" },
      { mode = "n", keys = '"' },
      { mode = "x", keys = "'" },
      { mode = "x", keys = "<Leader>" },
      { mode = "x", keys = "`" },
      { mode = "x", keys = "g" },
      { mode = "x", keys = "z" },
      { mode = "x", keys = '"' },
    },

    clues = {
      MiniClue.gen_clues.builtin_completion(),
      MiniClue.gen_clues.g(),
      MiniClue.gen_clues.marks(),
      MiniClue.gen_clues.registers(),
      MiniClue.gen_clues.windows(),
      MiniClue.gen_clues.z(),
      { mode = "n", keys = "<leader>b", desc = "+debug" },
      { mode = "n", keys = "<leader>d", desc = "+diffview" },
      { mode = "n", keys = "<leader>f", desc = "+find" },
      { mode = "n", keys = "<leader>g", desc = "+git" },
      { mode = "n", keys = "<leader>h", desc = "+hunk" },
      { mode = "n", keys = "<leader>l", desc = "+lsp" },
      { mode = "n", keys = "<leader>o", desc = "+orgmode" },
      { mode = "n", keys = "<leader>s", desc = "+session" },
      { mode = "n", keys = "<leader>t", desc = "+toggle" },
    },

    window = {
      -- Floating window config
      config = function(bufnr)
        local max_width = 0
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
          max_width = math.max(max_width, vim.fn.strchars(line))
        end

        -- Keep some right padding.
        max_width = max_width + 2

        return {
          border = "rounded",
          -- Dynamic width capped at 45.
          width = math.min(45, max_width),
        }
      end,

      -- Delay before showing clue window
      delay = 300,

      -- Keys to scroll inside the clue window
      scroll_down = "<C-d>",
      scroll_up = "<C-u>",
    },
  })
end

local function mini_diff_setup()
  require("mini.diff").setup({
    mappings = { textobject = "ih" },
    options = { wrap_goto = true },
  })
  vim.keymap.set("n", "<leader>hR", function()
    MiniDiff.do_hunks(0, "reset")
  end, { remap = true, desc = "Reset all buffer hunks" })
  vim.keymap.set("n", "<leader>hS", function()
    MiniDiff.do_hunks(0, "apply")
  end, { remap = true, desc = "Stage all buffer hunks" })
  vim.keymap.set("n", "<leader>ho", MiniDiff.toggle_overlay, { desc = "Toggle diff overlay" })
  vim.keymap.set("n", "<leader>hr", "gHih", { remap = true, desc = "Reset hunk" })
  vim.keymap.set("n", "<leader>hs", "ghih", { remap = true, desc = "Stage hunk" })
  vim.keymap.set("v", "<leader>hr", "gH", { remap = true, desc = "Reset selection" })
  vim.keymap.set("v", "<leader>hs", "gh", { remap = true, desc = "Stage selection" })
end

local function mini_files_setup()
  local MiniFiles = require("mini.files")
  local show_dotfiles = false

  local filter_show = function()
    return true
  end

  local filter_hide = function(fs_entry)
    return not vim.startswith(fs_entry.name, ".") and not vim.endswith(fs_entry.name, "__virtual.html")
  end

  local toggle_dotfiles = function()
    show_dotfiles = not show_dotfiles
    local new_filter = show_dotfiles and filter_show or filter_hide
    MiniFiles.refresh({ content = { filter = new_filter } })
  end

  local files_set_cwd = function()
    local cur_entry_path = MiniFiles.get_fs_entry().path
    local cur_directory = vim.fs.dirname(cur_entry_path)
    if vim.fn.chdir(cur_directory) ~= "" then
      print("Current directory set to " .. cur_directory)
    else
      print("Unable to set current directory")
    end
  end

  local map_split = function(buf_id, lhs, direction)
    local rhs = function()
      local fs_entry = MiniFiles.get_fs_entry()
      local is_at_file = fs_entry ~= nil and fs_entry.fs_type == "file"

      if is_at_file then
        local cur_target = MiniFiles.get_explorer_state().target_window
        local new_target = vim.api.nvim_win_call(cur_target, function()
          vim.cmd(direction .. " split")
          return vim.api.nvim_get_current_win()
        end)
        MiniFiles.set_target_window(new_target)
      end

      MiniFiles.go_in({})
    end

    local desc = "Split " .. direction
    vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
  end

  local open_terminal = function()
    local path = vim.fn.fnamemodify(MiniFiles.get_fs_entry().path, ":h")
    local term = require("toggleterm.terminal").Terminal:new({
      direction = "tab",
      dir = path,
      on_open = function(term)
        vim.keymap.set({ "n", "t" }, "<c-\\>", function()
          term:shutdown()
        end, { buffer = 0 })
      end,
    })
    term:toggle()
  end

  local yank_relative_path = function()
    local path = vim.fn.fnamemodify(MiniFiles.get_fs_entry().path, ":.")
    vim.fn.setreg(vim.v.register, path)
    print("Yanked relative path " .. path)
  end

  local yank_full_path = function()
    local path = MiniFiles.get_fs_entry().path
    vim.fn.setreg(vim.v.register, path)
    print("Yanked full path " .. path)
  end

  local minifiles_triggers = vim.api.nvim_create_augroup("MiniFilesMappings", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = minifiles_triggers,
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local buf_id = args.data.buf_id
      map_split(buf_id, "gs", "horizontal")
      map_split(buf_id, "gv", "vertical")
      vim.keymap.set("n", "-", function()
        MiniFiles.go_out()
      end, { buffer = buf_id, desc = "Go out of directory" })
      vim.keymap.set("n", "<c-\\>", open_terminal, { buffer = buf_id, desc = "Open folder in terminal" })
      vim.keymap.set("n", "<c-h>", toggle_dotfiles, { buffer = buf_id, desc = "Toggle hidden files" })
      vim.keymap.set("n", "<c-j>", "<c-j>", { buffer = buf_id, desc = "Down" })
      vim.keymap.set("n", "<c-k>", "k", { buffer = buf_id, desc = "Up" })
      vim.keymap.set("n", "<c-l>", "<c-l>", { buffer = buf_id, desc = "Clear and redraw screen" })
      vim.keymap.set("n", "<c-q>", function()
        MiniFiles.close()
      end, { buffer = buf_id, desc = "Close" })
      vim.keymap.set("n", "<cr>", function()
        local fs_entry = MiniFiles.get_fs_entry()
        local is_at_file = fs_entry ~= nil and fs_entry.fs_type == "file"
        MiniFiles.go_in({})
        if is_at_file then
          MiniFiles.close()
        end
      end, { buffer = buf_id, desc = "Go in entry" })
      vim.keymap.set("n", "<esc>", function()
        MiniFiles.close()
      end, { buffer = buf_id, desc = "Close" })
      vim.keymap.set("n", "g.", files_set_cwd, { buffer = buf_id, desc = "Set CWD" })
      vim.keymap.set("n", "gY", yank_full_path, { buffer = buf_id, desc = "Yank full path" })
      vim.keymap.set("n", "gh", "h", { buffer = buf_id, desc = "Left" })
      vim.keymap.set("n", "gl", "l", { buffer = buf_id, desc = "Right" })
      vim.keymap.set("n", "gy", yank_relative_path, { buffer = buf_id, desc = "Yank relative path" })
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesActionRename",
    callback = function(event)
      require("snacks").rename.on_rename_file(event.data.from, event.data.to)
    end,
  })

  MiniFiles.setup({
    content = {
      filter = filter_hide,
    },
    mappings = {
      close = "q",
      go_in = "<tab>",
      go_in_plus = "l",
      go_out = "h",
      go_out_plus = "",
      reset = "<bs>",
      reveal_cwd = "@",
      show_help = "g?",
      synchronize = "<c-s>",
      trim_left = "<",
      trim_right = ">",
    },
    windows = {
      preview = true,
      width_focus = 40,
      width_preview = 30,
    },
  })

  local function dynamic_open(path)
    MiniFiles.open(path, true, { windows = { width_preview = 30 + math.max(0, math.min(50, vim.o.columns - 120)) } })
  end

  vim.keymap.set("n", "\\", function()
    if not MiniFiles.close() then
      dynamic_open(".")
    end
  end, { desc = "Open file browser" })
  vim.keymap.set("n", "-", function()
    dynamic_open(vim.api.nvim_buf_get_name(0))
    MiniFiles.reveal_cwd()
  end, { desc = "Open file browser" })
end

local function mini_git_setup()
  require("mini.git").setup({})
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("MiniGitFolds", { clear = true }),
    pattern = { "git", "diff" },
    callback = function()
      vim.cmd("setlocal foldmethod=expr foldexpr=v:lua.MiniGit.diff_foldexpr()")
    end,
  })
  vim.keymap.set({ "n", "x" }, "<leader>gs", function()
    MiniGit.show_at_cursor()
  end, { desc = "Git show details" })
  vim.keymap.set("n", "<leader>gC", "<cmd>Git commit<cr>", { desc = "Git commit" })
  vim.keymap.set("n", "<leader>gP", "<cmd>Git push<cr>", { desc = "Git push" })
  vim.keymap.set("n", "<leader>gp", "<cmd>Git pull<cr>", { desc = "Git pull" })
  vim.keymap.set("n", "<leader>gZ", "<cmd>Git stash push<cr>", { desc = "Git stash push" })
  vim.keymap.set("n", "<leader>gz", "<cmd>Git stash pop<cr>", { desc = "Git stash pop" })
end

local function mini_indentscope_setup()
  vim.g.miniindentscope_disable = true
  require("mini.indentscope").setup({
    options = { indent_at_cursor = false },
  })
end

local function mini_map_setup()
  local MiniMap = require("mini.map")
  require("mini.map").setup({
    integrations = {
      MiniMap.gen_integration.builtin_search(),
      MiniMap.gen_integration.diagnostic(),
      MiniMap.gen_integration.diff(),
    },
    symbols = {
      encode = MiniMap.gen_encode_symbols.dot("4x2"),
    },
    window = { zindex = 30 },
  })

  vim.api.nvim_create_autocmd({ "SessionLoadPost", "TabEnter", "VimEnter" }, {
    group = vim.api.nvim_create_augroup("MiniMapShow", { clear = true }),
    callback = function()
      if vim.g.show_mini_map then
        MiniMap.open()
      else
        MiniMap.close()
      end
    end,
  })

  vim.keymap.set("n", "<leader>tm", function()
    vim.g.show_mini_map = not vim.g.show_mini_map
    if vim.g.show_mini_map then
      MiniMap.open()
    else
      MiniMap.close()
    end
  end, { desc = "Toggle mini.map" })

  vim.keymap.set("n", "<leader>tj", MiniMap.toggle_focus, { desc = "Jump to mini.map" })

  for _, key in ipairs({ "n", "N", "*", "#" }) do
    vim.keymap.set("n", key, key .. "<cmd>lua MiniMap.refresh({}, {lines = false, scrollbar = false})<cr>")
  end
  vim.keymap.set(
    "n",
    "<esc>",
    "<cmd>nohlsearch<bar>diffupdate<bar>lua MiniMap.refresh({}, {lines = false, scrollbar = false})<cr>",
    { desc = "Clear search highlights" }
  )
end

local function mini_pick_setup()
  local MiniPick = require("mini.pick")
  MiniPick.setup({
    mappings = {
      choose_alt = {
        char = "<cr>",
        func = function()
          vim.api.nvim_input("<cr>")
        end,
      },
      mark = "<c-space>",
      mark_and_move_down = {
        char = "<tab>",
        func = function()
          local mappings = MiniPick.get_picker_opts().mappings
          vim.api.nvim_input(mappings.mark .. mappings.move_down)
        end,
      },
      mark_and_move_up = {
        char = "<s-tab>",
        func = function()
          local mappings = MiniPick.get_picker_opts().mappings
          vim.api.nvim_input(mappings.mark .. mappings.move_up)
        end,
      },
      move_down_alt = {
        char = "<c-j>",
        func = function()
          local mappings = MiniPick.get_picker_opts().mappings
          vim.api.nvim_input(mappings.move_down)
        end,
      },
      refine = "<c-e>",
      toggle_info = "<c-o>",
      toggle_preview = "<c-k>",
      quickfix = {
        char = "<c-q>",
        func = function()
          local items = MiniPick.get_picker_matches()
          if items == nil then
            return
          end
          if #items.marked > 0 then
            MiniPick.default_choose_marked(items.marked)
          else
            MiniPick.default_choose_marked(items.all)
          end
          MiniPick.stop()
        end,
      },
    },
  })
  vim.ui.select = MiniPick.ui_select
  MiniPick.registry.read_session = function()
    local items = vim.tbl_values(require("mini.sessions").detected)
    local current = vim.fn.fnamemodify(vim.v.this_session, ":t")
    table.sort(items, function(a, b)
      if a.name == current then
        return false
      elseif b.name == current then
        return true
      end
      return a.modify_time > b.modify_time
    end)
    for _, value in pairs(items) do
      value.text = value.name .. " (" .. value.type .. ")"
    end
    local selection = MiniPick.start({
      source = {
        items = items,
        name = "Read Session",
        choose = function() end,
      },
    })
    if selection ~= nil then
      if confirm_discard_changes() then
        require("mini.sessions").read(selection.name, { force = true })
      end
    end
  end
  local MiniFuzzy = require("mini.fuzzy")
  local MiniVisits = require("mini.visits")
  MiniPick.registry.frecency = function()
    local visit_paths = MiniVisits.list_paths()
    local current_file = vim.fn.expand("%")
    MiniPick.builtin.files(nil, {
      source = {
        match = function(stritems, indices, query)
          -- Concatenate prompt to a single string
          local prompt = vim.pesc(table.concat(query))

          -- If ignorecase is on and there are no uppercase letters in prompt,
          -- convert paths to lowercase for matching purposes
          local convert_path = function(str)
            return str
          end
          if vim.o.ignorecase and string.find(prompt, "%u") == nil then
            convert_path = function(str)
              return string.lower(str)
            end
          end

          local current_file_cased = convert_path(current_file)
          local paths_length = #visit_paths

          -- Flip visit_paths so that paths are lookup keys for the index values
          local flipped_visits = {}
          for index, path in ipairs(visit_paths) do
            local key = vim.fn.fnamemodify(path, ":.")
            flipped_visits[convert_path(key)] = index - 1
          end

          local result = {}
          for _, index in ipairs(indices) do
            local path = stritems[index]
            local match_score = prompt == "" and 0 or MiniFuzzy.match(prompt, path).score
            if match_score >= 0 then
              local visit_score = flipped_visits[path] or paths_length
              table.insert(result, {
                index = index,
                -- Give current file high value so it's ranked last
                score = path == current_file_cased and 999999 or match_score + visit_score * 10,
              })
            end
          end

          table.sort(result, function(a, b)
            return a.score < b.score
          end)

          return vim.tbl_map(function(val)
            return val.index
          end, result)
        end,
      },
    })
  end

  vim.keymap.set("n", "<leader>f<leader>", "<cmd>Pick resume<cr>", { desc = "Resume last search" })
  vim.keymap.set("n", "<leader>fb", function()
    MiniPick.builtin.buffers(nil, {
      mappings = {
        wipeout = {
          char = "<c-x>",
          func = function()
            local matches = MiniPick.get_picker_matches()
            if matches == nil then
              return
            end
            local removals = matches.marked
            if #removals == 0 then
              removals = { matches.current }
            end
            local result = {}
            for _, item in ipairs(matches.all) do
              if vim.tbl_contains(removals, item) then
                vim.api.nvim_buf_delete(item.bufnr, {})
              else
                table.insert(result, item)
              end
            end
            MiniPick.set_picker_items(result, { do_match = true })
          end,
        },
      },
    })
  end, { desc = "Find buffers" })
  vim.keymap.set("n", "<leader>fC", "<cmd>Pick list scope='change'<cr>", { desc = "Find in changelist" })
  vim.keymap.set("n", "<leader>:", "<cmd>Pick commands<cr>", { desc = "Find commands" })
  vim.keymap.set("n", "<leader>fe", "<cmd>Pick explorer<cr>", { desc = "Find via file explorer" })
  vim.keymap.set("n", "<leader>fD", "m'<cmd>Pick lsp scope='declaration'<cr>", { desc = "Find LSP declaration" })
  vim.keymap.set("n", "<leader>fd", "m'<cmd>Pick lsp scope='definition'<cr>", { desc = "Find LSP definition" })
  vim.keymap.set("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
  vim.keymap.set("n", "<leader>gb", "<cmd>Pick git_branches<cr>", { desc = "Find branches" })
  vim.keymap.set("n", "<leader>gc", "<cmd>Pick git_commits<cr>", { desc = "Find commits" })
  vim.keymap.set("n", "<leader>gd", "<cmd>Pick git_files scope='deleted'<cr>", { desc = "Find deleted files" })
  vim.keymap.set("n", "<leader>gf", "<cmd>Pick git_files<cr>", { desc = "Find tracked files" })
  vim.keymap.set("n", "<leader>gh", "<cmd>Pick git_hunks<cr>", { desc = "Find hunks" })
  vim.keymap.set("n", "<leader>gi", "<cmd>Pick git_files scope='ignored'<cr>", { desc = "Find ignored files" })
  vim.keymap.set("n", "<leader>gm", "<cmd>Pick git_files scope='modified'<cr>", { desc = "Find modified files" })
  vim.keymap.set("n", "<leader>gu", "<cmd>Pick git_files scope='untracked'<cr>", { desc = "Find untracked files" })
  vim.keymap.set("n", "<leader>fG", "<cmd>Pick grep<cr>", { desc = "Find with grep" })
  vim.keymap.set("n", "<leader>fg", "<cmd>Pick grep_live<cr>", { desc = "Find with live grep" })
  vim.keymap.set("n", "<leader>fH", "<cmd>Pick hl_groups<cr>", { desc = "Find highlight groups" })
  vim.keymap.set("n", "<leader>fh", "<cmd>Pick help<cr>", { desc = "Find help documents" })
  vim.keymap.set("n", "<leader>fi", "<cmd>Pick diagnostic<cr>", { desc = "Find diagnostics" })
  vim.keymap.set("n", "<leader>fj", "<cmd>Pick list scope='jump'<cr>", { desc = "Find in jumplist" })
  vim.keymap.set("n", "<leader>fk", "<cmd>Pick keymaps<cr>", { desc = "Find keymaps" })
  vim.keymap.set("n", "<leader>fl", "<cmd>Pick buf_lines scope='current'<cr>", { desc = "Find current buffer lines" })
  vim.keymap.set("n", "<leader>fL", "<cmd>Pick buf_lines<cr>", { desc = "Find all buffer lines" })
  vim.keymap.set("n", "<leader>fM", "<cmd>Pick marks<cr>", { desc = "Find marks" })
  vim.keymap.set("n", "<leader>fo", "<cmd>Pick options<cr>", { desc = "Find Neovim options" })
  vim.keymap.set("n", "<leader>fo", "<cmd>Pick oldfiles<cr>", { desc = "Find oldfiles" })
  vim.keymap.set("n", "<leader>fR", "<cmd>Pick registers<cr>", { desc = "Find registers" })
  vim.keymap.set("n", "<leader>fr", "m'<cmd>Pick lsp scope='references'<cr>", { desc = "Find LSP references" })
  vim.keymap.set(
    "n",
    "<leader>fS",
    "m'<cmd>Pick lsp scope='workspace_symbol'<cr>",
    { desc = "Find LSP workspace symbol" }
  )
  vim.keymap.set(
    "n",
    "<leader>fs",
    "m'<cmd>Pick lsp scope='document_symbol'<cr>",
    { desc = "Find LSP document symbol" }
  )
  vim.keymap.set("n", "<leader>fT", "<cmd>Pick treesitter<cr>", { desc = "Find treesitter nodes" })
  vim.keymap.set("n", "<leader>ft", "<cmd>Pick lsp scope='type_definition'<cr>", { desc = "Find LSP type definition" })
  vim.keymap.set("n", "<leader>fq", "<cmd>Pick list scope='quickfix'<cr>", { desc = "Find in quickfix list" })
  vim.keymap.set("n", "<leader>fw", "<cmd>Pick grep pattern='<cword>'<cr>", { desc = "Find current word" })
  vim.keymap.set("n", "<leader>fz", "<cmd>Pick spellsuggest<cr>", { desc = "Find spelling suggestions" })
  vim.keymap.set("n", "z=", function()
    if vim.v.count > 0 then
      return vim.v.count .. "z="
    else
      return "<cmd>Pick spellsuggest<cr>"
    end
  end, { desc = "Find spelling suggestions", expr = true })
  vim.keymap.set("x", "<leader>f", 'y<cmd>Pick grep<cr><c-r>"<cr>', { desc = "Find current selection" })
end

local function mini_sessions_setup()
  local MiniSessions = require("mini.sessions")
  MiniSessions.setup({ autowrite = true })
  vim.keymap.set("n", "<leader>sd", function()
    MiniSessions.select("delete")
  end, { desc = "Delete session" })
  vim.keymap.set("n", "<leader>ss", "<cmd>Pick read_session<cr>", { desc = "Select session" })
  vim.keymap.set("n", "<leader>sw", function()
    vim.ui.input({
      prompt = "Session Name: ",
      default = vim.v.this_session ~= "" and vim.v.this_session or vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
    }, function(input)
      if input ~= nil then
        MiniSessions.write(input, { force = true })
      end
    end)
  end, { desc = "Save session" })
  vim.keymap.set("n", "<leader>sx", function()
    if confirm_discard_changes() then
      vim.v.this_session = ""
      vim.cmd("%bwipeout!")
      vim.cmd("cd ~")
    end
  end, { desc = "Clear current session" })
end

local function mini_surround_setup()
  require("mini.surround").setup({
    mappings = {
      add = "ys",
      delete = "ds",
      find = "",
      find_left = "",
      highlight = "",
      replace = "cs",
      update_n_lines = "",
    },
    n_lines = 50,
    search_method = "cover_or_next",
  })
  vim.keymap.del("x", "ys")
  vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
  vim.keymap.set("n", "yss", "ys_", { remap = true })
end

return {
  "echasnovski/mini.nvim",
  version = false,
  lazy = false,
  priority = 1000,
  config = function()
    mini_ai_setup()

    require("mini.align").setup({})

    mini_bracketed_setup()

    require("mini.comment").setup({})

    mini_diff_setup()

    require("mini.extra").setup({})

    require("mini.fuzzy").setup({})

    require("mini.move").setup({})

    local MiniOperators = require("mini.operators")
    MiniOperators.setup({ exchange = { prefix = "" }, replace = { prefix = "s" } })
    MiniOperators.make_mappings("exchange", { textobject = "sx", line = "sxx", selection = "X" })
    vim.keymap.set("n", "S", "s$", { remap = true, desc = "Substitute to end of line" })
    vim.keymap.set("n", "sX", "sx$", { remap = true, desc = "Exchange to end of line" })

    require("mini.splitjoin").setup({
      detect = { separator = "[,;]" },
      join = {
        hooks_post = { require("mini.splitjoin").gen_hook.pad_brackets({ brackets = { "%b[]", "%b{}" } }) },
      },
    })

    mini_surround_setup()

    if not vim.g.vscode then
      mini_clue_setup()

      require("mini.bufremove").setup({})
      vim.keymap.set("n", "<leader>x", function()
        if confirm_discard_changes(false) then
          require("mini.bufremove").delete(0, true)
        end
      end, { desc = "Close buffer" })

      mini_files_setup()

      mini_git_setup()

      local MiniIcons = require("mini.icons")
      MiniIcons.setup({})
      MiniIcons.mock_nvim_web_devicons()

      mini_indentscope_setup()

      -- mini_map_setup()

      -- local MiniMisc = require("mini.misc")
      -- MiniMisc.setup({})
      -- MiniMisc.setup_auto_root()
      -- vim.keymap.set("n", "<leader>z", function()
      --   MiniMisc.zoom(0, { width = vim.o.columns, height = vim.o.lines })
      -- end, { desc = "Zoom current buffer" })

      mini_pick_setup()

      mini_sessions_setup()

      -- require("mini.statusline").setup({})

      require("mini.visits").setup({})
      vim.keymap.set("n", "<leader><leader>", "<cmd>Pick frecency<cr>", { desc = "Select recent file" })
    end
  end,
}
