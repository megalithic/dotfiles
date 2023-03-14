-- local M = {
--   "lewis6991/gitsigns.nvim",
--   event = { "BufReadPost", "BufNewFile" },
--   config = function()
--     local gs = require("gitsigns")
--     gs.setup({
--       signs = {
--         add = { hl = "GitSignsAdd", text = "▎" }, -- alts: ┃, │, ▌, ▎ 🮉
--         change = { hl = "GitSignsChange", text = "▎" }, -- alts: ║▎
--         delete = { hl = "GitSignsDelete", text = "┊" }, -- alts: ▎▎
--         topdelete = { hl = "GitSignsDelete", text = "" }, -- alts: ▌
--         changedelete = { hl = "GitSignsChange", text = "▌" },
--         untracked = { hl = "GitSignsAdd", text = "│" },
--         -- untracked = { hl = "GitSignsAdd", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
--       },
--       _threaded_diff = true,
--       _extmark_signs = true,
--       _signs_staged_enable = true,
--       preview_config = {
--         border = mega.get_border(),
--       },
--       word_diff = false,
--       numhl = false,
--       current_line_blame = false,
--       current_line_blame_formatter = "<author>, <author_time:%R> • <summary>",
--       current_line_blame_opts = {
--         virt_text = true,
--         virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
--         delay = 1,
--         ignore_whitespace = false,
--       },
--       on_attach = function(bufnr)
--         local gs = package.loaded.gitsigns
--
--         local function map(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc }) end
--
--         map("n", "]h", gs.next_hunk, "Next Hunk")
--         map("n", "[h", gs.prev_hunk, "Prev Hunk")
--         map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
--         map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
--         map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
--         map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
--         map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
--         map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
--         map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
--         map("n", "<leader>ghd", gs.diffthis, "Diff This")
--         map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
--         map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
--       end,
--       -- keymaps = {
--       --   -- Default keymap options
--       --   noremap = true,
--       --   buffer = true,
--       --   ["n [h"] = { expr = true, "&diff ? ']h' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'" },
--       --   ["n ]h"] = { expr = true, "&diff ? '[h' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'" },
--       --   ["n <localleader>gw"] = "<cmd>lua require\"gitsigns\".stage_buffer()<CR>",
--       --   ["n <localleader>gre"] = "<cmd>lua require\"gitsigns\".reset_buffer()<CR>",
--       --   ["n <localleader>gbl"] = "<cmd>lua require\"gitsigns\".blame_line()<CR>",
--       --   ["n <localleader>gbd"] = "<cmd>lua require\"gitsigns\".toggle_word_diff()<CR>",
--       --   -- ["n <leader>lm"] = "<cmd>lua require\"gitsigns\".setqflist(\"all\")<CR>",
--       --   -- Text objects
--       --   ["o ih"] = ":<C-U>lua require\"gitsigns\".select_hunk()<CR>",
--       --   ["x ih"] = ":<C-U>lua require\"gitsigns\".select_hunk()<CR>",
--       --   ["n <leader>hs"] = "<cmd>lua require\"gitsigns\".stage_hunk()<CR>",
--       --   ["v <leader>hs"] = "<cmd>lua require\"gitsigns\".stage_hunk({vim.fn.line(\".\"), vim.fn.line(\"v\")})<CR>",
--       --   ["n <leader>hu"] = "<cmd>lua require\"gitsigns\".undo_stage_hunk()<CR>",
--       --   ["n <leader>hr"] = "<cmd>lua require\"gitsigns\".reset_hunk()<CR>",
--       --   ["v <leader>hr"] = "<cmd>lua require\"gitsigns\".reset_hunk({vim.fn.line(\".\"), vim.fn.line(\"v\")})<CR>",
--       --   ["n <leader>hp"] = "<cmd>lua require\"gitsigns\".preview_hunk()<CR>",
--       --   ["n <leader>hb"] = "<cmd>lua require\"gitsigns\".blame_line()<CR>",
--       -- },
--     })
--   end,
-- }

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { hl = "GitSignsAdd", text = "▎" }, -- alts: ┃, │, ▌, ▎ 🮉
      change = { hl = "GitSignsChange", text = "▎" }, -- alts: ║▎
      delete = { hl = "GitSignsDelete", text = "┊" }, -- alts: ▎▎
      topdelete = { hl = "GitSignsDelete", text = "" }, -- alts: ▌
      changedelete = { hl = "GitSignsChange", text = "▌" },
      untracked = { hl = "GitSignsAdd", text = "│" },
    },
    preview_config = {
      border = mega.get_border(),
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      -- local function map(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc }) end
      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end
      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(function() gs.next_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "git: next hunk" })
      map("n", "[c", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(function() gs.prev_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "git: prev hunk" })
      -- Actions
      map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "git: stage hunk" })
      map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "git: reset hunk" })
      -- map("n", "<leader>hS", gs.stage_buffer)
      -- map("n", "<leader>hu", gs.undo_stage_hunk)
      -- map("n", "<leader>hR", gs.reset_buffer)
      map("n", "<leader>hp", gs.preview_hunk, { desc = "git: preview hunk" })
      -- map("n", "<leader>hb", function()
      --   gs.blame_line { full = true }
      -- end)
      -- map("n", "<leader>tb", gs.toggle_current_line_blame)
      -- map("n", "<leader>hd", gs.diffthis)
      -- map("n", "<leader>hD", function()
      --   gs.diffthis("~")
      -- end)
      -- map("n", "<leader>td", gs.toggle_deleted)

      -- Text object
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "git: select hunk" })

      -- orig
      --   map("n", "]h", gs.next_hunk, "Next Hunk")
      --   map("n", "[h", gs.prev_hunk, "Prev Hunk")
      --   map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
      --   map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
      --   map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
      --   map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
      --   map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
      --   map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
      --   map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
      --   map("n", "<leader>ghd", gs.diffthis, "Diff This")
      --   map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
      --   map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
    end,
  },
}
