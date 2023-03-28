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

do
  local orig_rename_handler = vim.lsp.handlers["textDocument/rename"]

  local function parse_edits(entries, bufnr, text_edits)
    for _, edit in ipairs(text_edits) do
      local start_line = edit.range.start.line + 1
      local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]

      table.insert(entries, {
        bufnr = bufnr,
        lnum = start_line,
        col = edit.range.start.character + 1,
        text = line,
      })
    end
  end

  -- Populates the quickfix list with all rename locations.
  vim.lsp.handlers["textDocument/rename"] = function(err, result, ...)
    orig_rename_handler(err, result, ...)
    if err then return end

    local entries = {}
    if result.changes then
      for uri, edits in pairs(result.changes) do
        local bufnr = vim.uri_to_bufnr(uri)
        parse_edits(entries, bufnr, edits)
      end
    elseif result.documentChanges then
      for _, doc_change in ipairs(result.documentChanges) do
        if doc_change.textDocument then
          local bufnr = vim.uri_to_bufnr(doc_change.textDocument.uri)
          parse_edits(entries, bufnr, doc_change.edits)
        else
          vim.notify(
            fmt("Failed to parse TextDocumentEdit of kind: %s", doc_change.kind or "N/A"),
            vim.log.levels.WARN,
            { title = "lsp" }
          )
        end
      end
    end
    vim.fn.setqflist(entries)
  end
end

function M.rename()
  local rename_prompt = ""
  local default_rename_prompt = " -> "
  local current_name = ""

  local function cleanup_rename_callback(winnr)
    api.nvim_win_close(winnr or 0, true)
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
      vim.notify("Rename text matches; try again.", vim.log.levels.WARN, { title = "lsp" })
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

    imap("<CR>", function() rename_callback() end, { buffer = bufnr })
    imap("<esc>", function() cleanup_rename_callback(winnr) end, { buffer = bufnr })
    imap("<c-c>", function() cleanup_rename_callback(winnr) end, { buffer = bufnr })

    vim.cmd("startinsert")
  end

  do_rename()
end

return M
