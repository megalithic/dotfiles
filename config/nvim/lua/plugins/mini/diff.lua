-- mini.diff with custom jj + hg sources.
-- Patterns adapted from:
--   https://github.com/madmaxieee/nvim-config/blob/main/lua/plugins/mini-diff/init.lua
--   https://github.com/madmaxieee/nvim-config/blob/main/lua/plugins/mini-diff/gen-custom-source.lua

local get_jj_root = function(path) return require("utils.vcs").get_jj_root(path) end
local get_hg_root = function(path) return require("utils.vcs").get_hg_root(path) end

---@alias DiffCacheEntry {fs_event:uv.uv_fs_event_t, timer:uv.uv_timer_t, attached?:string}

---@type table<integer, DiffCacheEntry>
local cache = {}

---@param cache_entry DiffCacheEntry?
local function cleanup(cache_entry)
  if cache_entry == nil then return end
  pcall(vim.uv.fs_event_stop, cache_entry.fs_event)
  pcall(vim.uv.timer_stop, cache_entry.timer)
end

---@class WatchPattern
---@field dir string
---@field file string

---@class DiffSourceOpts
---@field name                  string
---@field should_enable?        fun(): boolean
---@field setup?                fun()
---@field get_root              fun(path: string): string?
---@field root_to_watch_pattern fun(root: string): WatchPattern
---@field async_get_ref_text    fun(path: string, callback: fun(text: string|string[]))

---@type fun(buf: integer, text: string|string[])
local set_ref_text = vim.schedule_wrap(function(buf, text)
  local ok, err = pcall(require("mini.diff").set_ref_text, buf, text)
  if not ok and err then vim.notify(err) end
end)

---@param buf integer
local function get_buf_realpath(buf) return vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf)) end

---@param buf integer used as the cache key
---@param watch_pattern WatchPattern
---@param callback fun()
local function start_watching(buf, watch_pattern, callback)
  local buf_fs_event = vim.uv.new_fs_event()
  if not buf_fs_event then
    vim.notify("Could not create new_fs_event")
    return
  end

  local timer = vim.uv.new_timer()
  if not timer then
    vim.notify("Could not create new_timer")
    buf_fs_event:stop()
    return
  end

  local debounced_cb = function(err, filename)
    if err then return end
    if watch_pattern.file and filename ~= watch_pattern.file then return end
    timer:stop()
    timer:start(50, 0, callback)
  end
  timer:start(0, 0, callback)

  buf_fs_event:start(watch_pattern.dir, { recursive = false }, debounced_cb)
  cleanup(cache[buf])
  cache[buf].fs_event = buf_fs_event
  cache[buf].timer = timer
end

---@param opts DiffSourceOpts
local function make_diff_source(opts)
  if not opts.should_enable then opts.should_enable = function() return true end end

  local name = opts.name

  if vim.fn.executable(name) ~= 1 or not opts.should_enable() then
    return {
      name = name,
      attach = function() return false end,
      detach = function(_) end,
    }
  end

  if opts.setup then opts.setup() end

  return {
    name = name,

    ---@param buf integer
    attach = function(buf)
      if cache[buf] ~= nil then return false end

      local path = get_buf_realpath(buf)
      if not path then return false end

      local root = opts.get_root(path)
      if not root then return false end

      cache[buf] = { attached = name }

      local watch_pattern = opts.root_to_watch_pattern(root)
      start_watching(buf, watch_pattern, function()
        opts.async_get_ref_text(path, function(text) set_ref_text(buf, text) end)
      end)
    end,

    ---@param buf integer
    detach = function(buf)
      local entry = cache[buf]
      if entry and entry.attached == name then
        cleanup(entry)
        cache[buf] = nil
      end
    end,
  }
end

-- ===========================================================================
-- Mercurial source
-- ===========================================================================

local hg_config = {
  base_rev = ".",
}

local function hg_cmd(...)
  local HG = {
    "hg",
    "--pager=never",
    "--color=never",
  }
  return vim.list_extend(HG, { ... })
end

---@type DiffSourceOpts
local hg_opts = {
  name = "hg",

  setup = function()
    vim.api.nvim_create_user_command("MiniHgDiff", function(args)
      local rev = args.args
      local path = vim.api.nvim_buf_get_name(0)
      local dir = vim.fs.dirname(path)
      vim.system(hg_cmd("identify", "--rev", rev), { cwd = dir }, function(res)
        if res.code ~= 0 then
          vim.schedule(function() vim.notify(("mini.diff hg: '%s' is not a valid rev"):format(rev)) end)
          return
        end
        hg_config.base_rev = rev
        for buf, entry in pairs(cache) do
          if entry.attached == "hg" then
            vim.schedule(function()
              require("mini.diff").disable(buf)
              require("mini.diff").enable(buf)
              vim.notify(("mini.diff hg: reference rev is set to '%s'"):format(rev))
            end)
          end
        end
      end)
    end, { nargs = 1 })

    vim.api.nvim_create_user_command("MiniHgPDiff", function()
      if hg_config.base_rev == "." then
        vim.cmd([[MiniHgDiff .^]])
      else
        vim.cmd([[MiniHgDiff .]])
      end
    end, { nargs = 0 })
  end,

  root_to_watch_pattern = function(root) return { dir = root .. "/.hg", file = "dirstate" } end,

  get_root = function(path) return get_hg_root(path) end,

  async_get_ref_text = function(path, callback)
    local dir = vim.fs.dirname(path)
    local file = vim.fs.basename(path)
    vim.system(hg_cmd("cat", "--rev", hg_config.base_rev, "--", file), { cwd = dir }, function(res)
      if res.code ~= 0 then return end
      local output = res.stdout or ""
      callback(output)
    end)
  end,
}

-- ===========================================================================
-- Jujutsu source
-- ===========================================================================

local jj_config = {
  base_rev = "@-",
}

local function jj_cmd(...)
  local JJ = {
    "jj",
    "--no-pager",
    "--color=never",
  }
  return vim.list_extend(JJ, { ... })
end

---@type DiffSourceOpts
local jj_opts = {
  name = "jj",

  setup = function()
    vim.api.nvim_create_user_command("MiniJJDiff", function(args)
      local rev = args.args
      local path = vim.api.nvim_buf_get_name(0)
      local dir = vim.fs.dirname(path)
      vim.system(jj_cmd("log", "-r", rev, "--no-graph", "-T", ""), { cwd = dir }, function(res)
        if res.code ~= 0 then
          vim.schedule(function() vim.notify(("mini.diff jj: '%s' is not a valid rev"):format(rev)) end)
          return
        end
        jj_config.base_rev = rev
        for buf, entry in pairs(cache) do
          if entry.attached == "jj" then
            vim.schedule(function()
              require("mini.diff").disable(buf)
              require("mini.diff").enable(buf)
              vim.notify(("mini.diff jj: reference rev is set to '%s'"):format(rev))
            end)
          end
        end
      end)
    end, { nargs = 1 })

    vim.api.nvim_create_user_command("MiniJJPDiff", function()
      if jj_config.base_rev == "@-" then
        vim.cmd([[MiniJJDiff @--]])
      else
        vim.cmd([[MiniJJDiff @-]])
      end
    end, { nargs = 0 })
  end,

  root_to_watch_pattern = function(root) return { dir = root .. "/.jj/working_copy", file = "checkout" } end,

  get_root = function(path) return get_jj_root(path) end,

  async_get_ref_text = function(path, callback)
    local dir = vim.fs.dirname(path)
    local file = vim.fs.basename(path)
    vim.system(
      jj_cmd("--ignore-working-copy", "file", "show", "-r", jj_config.base_rev, "--", file),
      { cwd = dir },
      function(res)
        if res.code ~= 0 then return end
        local output = res.stdout or ""
        callback(output)
      end
    )
  end,
}

local gen_custom_source = {
  hg = function() return make_diff_source(hg_opts) end,
  jj = function() return make_diff_source(jj_opts) end,
}

return {
  "nvim-mini/mini.diff",
  event = "VeryLazy",
  config = function()
    require("mini.diff").setup({
      view = {
        style = "sign",
        signs = {
          add = "│",
          change = "│",
          delete = "󰍵",
        },
      },
      mappings = {
        apply = "",
        reset = "",
        textobject = "",
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
      },
      options = {
        algorithm = "patience",
      },
      source = {
        gen_custom_source.hg(),
        gen_custom_source.jj(),
        require("mini.diff").gen_source.git(),
        require("mini.diff").gen_source.save(),
        require("mini.diff").gen_source.none(),
      },
    })

    local map_repeatable_pair = mega.u.map_repeatable_pair
    local map = mega.u.safe_keymap_set

    map_repeatable_pair({ "n" }, {
      next = {
        "]h",
        function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            require("mini.diff").goto_hunk("next", { wrap = true })
          end
        end,
        { desc = "Next hunk" },
      },
      prev = {
        "[h",
        function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            require("mini.diff").goto_hunk("prev", { wrap = true })
          end
        end,
        { desc = "Previous hunk" },
      },
    })

    local MINI_DIFF_TEXTOBJECT = "ih"

    map(
      { "o", "x" },
      MINI_DIFF_TEXTOBJECT,
      function() require("mini.diff").textobject() end,
      { desc = "Current hunk text object" }
    )

    map("n", "<leader>hr", function() return require("mini.diff").operator("reset") .. MINI_DIFF_TEXTOBJECT end, {
      expr = true,
      remap = true,
      desc = "Reset current hunk",
    })

    map({ "x" }, "<leader>hr", function() return require("mini.diff").operator("reset") end, {
      expr = true,
      desc = "Reset selected lines",
    })

    map("n", "<leader>gd", function() require("mini.diff").toggle_overlay(0) end, { desc = "Toggle diff overlay" })
  end,
}
