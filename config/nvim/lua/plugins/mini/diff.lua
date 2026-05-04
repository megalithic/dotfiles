-- mini.diff with custom jj source.
-- Patterns adapted from:
--   https://github.com/madmaxieee/nvim-config/blob/main/lua/plugins/mini-diff/init.lua
--   https://github.com/madmaxieee/nvim-config/blob/main/lua/plugins/mini-diff/jj-source.lua
--   https://github.com/madmaxieee/nvim-config/blob/main/lua/plugins/mini-diff/make-source.lua

local make_source = require("plugins.mini.diff.make-source")
local jj = require("utils.jj")
local co2 = require("co2")

-- ── Jujutsu source ───────────────────────────────────────────────────────

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

  should_enable = function()
    return jj.find_root(vim.uv.cwd()) ~= nil
  end,

  root_to_watch_pattern = function(root) return { dir = root .. "/.jj/working_copy", file = "checkout" } end,

  get_root = jj.find_root,

  async_get_ref_text = co2.wrap(function(ctx, path, callback)
    local dir = vim.fs.dirname(path)
    local file = vim.fs.basename(path)

    local res = ctx.await(
      vim.system,
      jj_cmd("--ignore-working-copy", "file", "show", "-r", jj.config.base_rev, "--", file),
      { cwd = dir }
    )

    if res.code == 0 then
      callback(res.stdout or "")
      return
    end

    -- If missing from base rev, check working copy (@) to differentiate
    -- between new files (diff against empty string → full-add signs) and
    -- ignored files (do nothing).
    local res2 = ctx.await(vim.system, jj_cmd("file", "show", "-r", "@", "--", file), { cwd = dir })
    if res2.code == 0 then callback("") end
  end),
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
        make_source.make_diff_source(jj_opts),
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
