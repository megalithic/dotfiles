return {
  "chrisgrieser/nvim-genghis",
  init = function()
    vim.g.whichkeyAddSpec({ "<localleader>f", group = "󰈔 File" })
    vim.g.whichkeyAddSpec({ "<localleader>y", group = "󰅍 Yank" })
  end,
  opts = {
    navigation = { onlySameExtAsCurrentFile = false },
  },
  keys = {
		-- stylua: ignore start
		{"<localleader>ya", function() require("genghis").copyFilepathWithTilde() end, desc = "󰝰 Absolute path" },
		{"<localleader>yr", function() require("genghis").copyRelativePath() end, desc = "󰝰 Relative path" },
		{"<localleader>yn", function() require("genghis").copyFilename() end, desc = "󰈔 Name of file" },
		{"<localleader>yp", function() require("genghis").copyDirectoryPath() end, desc = "󰝰 Parent path" },
		{"<localleader>yf", function() require("genghis").copyFileItself() end, desc = "󱉥 File (macOS)" },

		{ "<M-CR>", function() require("genghis").navigateToFileInFolder("next") end, desc = "󰖽 Next file in folder" },
		{ "<S-M-CR>", function() require("genghis").navigateToFileInFolder("prev") end, desc = "󰖿 Prev file in folder" },
		{ "<D-l>", function() require("genghis").showInSystemExplorer() end, desc = "󰀶 Reveal in Finder" },
    -- stylua: ignore end

    { "<localleader>fr", function() require("genghis").renameFile() end, desc = "󰑕 Rename" },
    { "<localleader>fw", function() require("genghis").duplicateFile() end, desc = " Duplicate" },
    { "<localleader>fm", function() require("genghis").moveToFolderInCwd() end, desc = "󱀱 Move" },
    { "<localleader>fd", function() require("genghis").trashFile() end, desc = "󰩹 Delete" },
    { "<localleader>fx", function() require("genghis").chmodx() end, desc = "󰒃 chmod +x" },

		-- stylua: ignore
		{ "<localleader>fn", function() require("genghis").createNewFileInFolder() end, desc = "󰝒 New in folder" },
    {
      "<localleader>fn",
      function() require("genghis").moveSelectionToNewFile() end,
      mode = "x",
      desc = "󰝒 New file from selection",
    },
    { "<leadlocaler>fN", function() require("genghis").createNewFile() end, desc = "󰝒 New" },
  },
}
