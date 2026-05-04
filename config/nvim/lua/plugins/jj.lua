return {
  {
    "NicolasGB/jj.nvim",
    version = "*",
    config = function() require("jj").setup({}) end,
    keys = {
      { "<leader>ja", function() require("jj.annotate").file() end, desc = "jj: annotate/blame current file" },
      { "<leader>jf", function() require("jj.picker").status() end, desc = "jj: status picker" },
      { "<leader>jl", function() require("jj.cmd").log() end, desc = "jj: log" },
      { "<leader>jh", function() require("jj.picker").file_history() end, desc = "jj: file history" },
      { "<leader>je", function() require("utils.jj").diffedit() end, desc = "jj: diffedit" },
      { "<leader>jd", function() require("jj.diff").open_vdiff({ rev = "trunk()" }) end, desc = "jj: vdiff vs trunk" },
    },
  },
}
