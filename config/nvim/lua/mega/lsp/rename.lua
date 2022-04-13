local api = vim.api
local lsp = vim.lsp
local fn = vim.fn

local M = {}

-- REFS:
-- * https://github.com/saadparwaiz1/dotfiles/blob/macOS/nvim/plugin/lsp.lua#L29-L74
-- * https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/rename.lua
-- * https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/lsp.lua#L197-L217
-- * https://github.com/akinsho/dotfiles/commit/59b5011d9533de0427fc34e687c9f1a566d6020c#diff-cc18199cc4302869fa6d36870b7950eef0b03021e5e93c64e17153b234ad6800R160
-- * https://github.com/axieax/dotconfig/blob/main/nvim/lua/axie/lsp/rename.lua

function M.rename()
  local rename_prompt = ""
  local default_rename_prompt = " -> "
  local current_name = ""

  local function cleanup_rename_callback()
    api.nvim_win_close(0, true)
    api.nvim_feedkeys(mega.replace_termcodes("<Esc>"), "i", true)

    current_name = ""
    rename_prompt = default_rename_prompt
  end

  local function rename_callback()
    local new_name = vim.trim(fn.getline("."):sub(#rename_prompt, -1))

    if new_name ~= current_name then
      cleanup_rename_callback()
      local params = lsp.util.make_position_params()
      params.newName = new_name
      lsp.buf_request(0, "textDocument/rename", params)
    else
      mega.warn("Rename text matches; try again.")
    end
  end

  local function do_rename()
    current_name = fn.expand("<cword>")
    rename_prompt = current_name .. default_rename_prompt
    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(bufnr, "buftype", "prompt")
    api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_option(bufnr, "filetype", "prompt")
    api.nvim_buf_add_highlight(bufnr, -1, "Title", 0, 0, #rename_prompt)
    fn.prompt_setprompt(bufnr, rename_prompt)
    local width = #current_name + #rename_prompt + 15
    local winnr = api.nvim_open_win(bufnr, true, {
      relative = "cursor",
      width = width,
      height = 1,
      row = -3,
      col = 1,
      style = "minimal",
      border = mega.get_border(),
    })

    api.nvim_win_set_option(
      winnr,
      "winhl",
      table.concat({
        "Normal:NormalFloat",
        "FloatBorder:FloatBorder",
        "CursorLine:Visual",
        "Search:None",
      }, ",")
    )
    api.nvim_win_set_option(winnr, "relativenumber", false)
    api.nvim_win_set_option(winnr, "number", false)

    imap("<CR>", function()
      rename_callback()
    end)
    imap("<esc>", function()
      cleanup_rename_callback()
    end)
    imap("<c-c>", function()
      cleanup_rename_callback()
    end)

    vim.cmd("startinsert")
  end

  do_rename()
end

return M
