-- lua/plugins/mini/pairs.lua
-- Auto-close brackets and quotes

return {
  "echasnovski/mini.pairs",
  event = "InsertEnter",
  opts = {
    modes = { insert = true, command = false, terminal = false },
    mappings = {
      -- Prevent adding 4th backtick in markdown
      ["`"] = { neigh_pattern = "[^\\`]." },
    },
  },
}
