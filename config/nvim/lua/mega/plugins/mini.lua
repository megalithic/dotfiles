local mini = {
  "echasnovski/mini.nvim",
  event = "VeryLazy",
}

local specs = { mini, "JoosepAlviste/nvim-ts-context-commentstring" }

function mini.surround()
  require("mini.surround").setup({
    mappings = {
      add = "ys",
      delete = "ds",
      -- find = "",
      -- find_left = "",
      -- highlight = "",
      replace = "cs",
      -- add = "yp",
      -- visual_add = "P",
      -- delete = "dp",
      -- find = "gp",
      -- find_left = "gP",
      -- replace = "cp",
      -- update_n_lines = "",
    },
    -- n_lines = 200,
    -- search_method = "cover_or_nearest", -- alts: cover_or_next
  })

  mega.xnoremap("S", [[:<C-u>lua MiniSurround.add('visual')<CR>]])
end

-- function mini.jump() require("mini.jump").setup({}) end

function mini.pairs() require("mini.pairs").setup({}) end

function mini.comment()
  require("mini.comment").setup({
    hooks = {
      pre = function() require("ts_context_commentstring.internal").update_commentstring({}) end,
    },
  })
end

function mini.ai()
  local ai = require("mini.ai")
  local gen_spec = ai.gen_spec
  ai.setup({
    n_lines = 500,
    -- search_method = "cover_or_next",
    custom_textobjects = {
      o = gen_spec.treesitter({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }, {}),
      f = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
      c = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
      -- scope
      s = gen_spec.treesitter({
        a = { "@function.outer", "@class.outer", "@testitem.outer" },
        i = { "@function.inner", "@class.inner", "@testitem.inner" },
      }),
      S = gen_spec.treesitter({
        a = { "@function.name", "@class.name", "@testitem.name" },
        i = { "@function.name", "@class.name", "@testitem.name" },
      }),
    },
    mappings = {
      around = "a",
      inside = "i",

      around_next = "an",
      inside_next = "in",
      around_last = "al",
      inside_last = "il",

      goto_left = "",
      goto_right = "",
    },
  })

  local ai_map = function(text_obj, desc)
    for _, side in ipairs({ "left", "right" }) do
      for dir, d in pairs({ prev = "[", next = "]" }) do
        local lhs = d .. (side == "right" and text_obj:upper() or text_obj:lower())
        for _, mode in ipairs({ "n", "x", "o" }) do
          vim.keymap.set(mode, lhs, function() ai.move_cursor(side, "a", text_obj, { search_method = dir }) end, {
            desc = dir .. " " .. desc,
          })
        end
      end
    end
  end

  ai_map("f", "function")
  ai_map("c", "class")
  ai_map("o", "block")
end

function mini.align()
  require("mini.align").setup({
    mappings = {
      start = "ga",
      start_with_preview = "gA",
    },
  })
end

function mini.indentscope()
  require("mini.indentscope").setup({
    -- symbol = "", -- │ ▏▏
    symbol = "┊", -- alts: ┆ ┊  ▎│
    draw = {
      delay = 0,
      animation = require("mini.indentscope").gen_animation.none(),
    },
    options = { try_as_border = true },
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "help",
      "alpha",
      "dashboard",
      "neo-tree",
      "Trouble",
      "lazy",
      "mason",
      "fzf",
      "dirbuf",
      "terminal",
      "fzf-lua",
      "fzflua",
      "megaterm",
      "nofile",
      "terminal",
      "megaterm",
      "lsp-installer",
      "lspinfo",
      "markdown",
      "help",
      "startify",
      "packer",
      "neogitstatus",
      "DirBuf",
      "markdown",
    },
    callback = function() vim.b.miniindentscope_disable = true end,
  })
end

function mini.config()
  -- mini.jump()
  mini.surround()
  mini.ai()
  mini.pairs()
  mini.comment()
  mini.align()
  -- mini.indentscope()
end

function mini.init()
  vim.keymap.set("n", "<leader>bd", function() require("mini.bufremove").delete(0, false) end)
  vim.keymap.set("n", "<leader>bD", function() require("mini.bufremove").delete(0, true) end)
end

return specs
