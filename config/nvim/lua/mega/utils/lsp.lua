local api = vim.api
local lsp = vim.lsp
local lsputil = require("lspconfig.util")
local fn = vim.fn

local M = {}

-- REFS:
-- * https://github.com/saadparwaiz1/dotfiles/blob/macOS/nvim/plugin/lsp.lua#L29-L74
-- * https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/rename.lua
-- * https://github.com/kristijanhusak/neovim-config/blob/master/nvim/lua/partials/lsp.lua#L197-L217
-- * https://github.com/akinsho/dotfiles/commit/59b5011d9533de0427fc34e687c9f1a566d6020c#diff-cc18199cc4302869fa6d36870b7950eef0b03021e5e93c64e17153b234ad6800R160
-- * https://github.com/axieax/dotconfig/blob/main/nvim/lua/axie/lsp/rename.lua

-- local orig_rename_handler = vim.lsp.handlers["textDocument/rename"]
--
-- local function parse_edits(entries, bufnr, text_edits)
--   for _, edit in ipairs(text_edits) do
--     local start_line = edit.range.start.line + 1
--     local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]
--
--     table.insert(entries, {
--       bufnr = bufnr,
--       lnum = start_line,
--       col = edit.range.start.character + 1,
--       text = line,
--     })
--   end
-- end
--
-- -- Populates the quickfix list with all rename locations.
-- vim.lsp.handlers["textDocument/rename"] = function(err, result, ...)
--   orig_rename_handler(err, result, ...)
--   if err then return end
--
--   local entries = {}
--   if result.changes then
--     for uri, edits in pairs(result.changes) do
--       local bufnr = vim.uri_to_bufnr(uri)
--       parse_edits(entries, bufnr, edits)
--     end
--   elseif result.documentChanges then
--     for _, doc_change in ipairs(result.documentChanges) do
--       if doc_change.textDocument then
--         local bufnr = vim.uri_to_bufnr(doc_change.textDocument.uri)
--         parse_edits(entries, bufnr, doc_change.edits)
--       else
--         vim.notify(
--           fmt("Failed to parse TextDocumentEdit of kind: %s", doc_change.kind or "N/A"),
--           vim.log.levels.WARN,
--           { title = "lsp" }
--         )
--       end
--     end
--   end
--   vim.fn.setqflist(entries)
-- end

function M.root_pattern(...)
  local patterns = vim.tbl_flatten({ ... })

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lsputil.search_ancestors(startpath, function(path)
        if lsputil.path.exists(fn.glob(lsputil.path.join(path, pattern))) then
          -- dd(fmt("found %s at %s", pattern, path))
          return path
        end
      end)
    end
  end
end

-- NOTE: prefer this one, i think? 2023/09/28
function M.root_dir(patterns, fname)
  if type(patterns) == "string" then patterns = { patterns } end
  if not fname or fname == "" then fname = vim.fn.getcwd() end

  local matches = vim.fs.find(patterns, { upward = true, limit = 2, path = fname })
  local child_or_root_path, maybe_umbrella_path = unpack(matches)

  return vim.fs.dirname(maybe_umbrella_path or child_or_root_path)
end

function M.setup_rename(_client, _bufnr)
  --
  --
  -- populate qf list with changes (if multiple files modified)
  local function qf_rename()
    local rename_prompt = ""
    local default_rename_prompt = " -> "
    local current_name = ""

    local position_params = vim.lsp.util.make_position_params()
    position_params.oldName = vim.fn.expand("<cword>")

    local function cleanup_rename_callback(winnr)
      api.nvim_win_close(winnr or 0, true)
      api.nvim_feedkeys(vim.keycode("<Esc>"), "i", true)

      current_name = ""
      rename_prompt = default_rename_prompt
    end

    local rename_callback = function()
      local input = vim.trim(fn.getline("."):sub(#rename_prompt, -1))

      if input == nil then
        vim.notify("aborted", L.WARN, { title = "[lsp] rename" })
        return
      elseif input == position_params.oldName then
        vim.notify("input text matches current text; try again.", L.WARN, { title = "[lsp] rename" })
        return
      end

      cleanup_rename_callback()

      position_params.newName = input

      lsp.buf_request(0, "textDocument/rename", position_params, function(err, result, ctx, config)
        -- result not provided, error at lsp end
        -- no changes made
        if not result or (not result.documentChanges and not result.changes) then
          vim.notify(
            string.format("could not perform rename: %s -> %s", position_params.oldName, position_params.newName),
            L.ERROR,
            { title = "[LSP] rename", timeout = 500 }
          )

          return
        end

        -- apply changes
        vim.lsp.handlers["textDocument/rename"](err, result, ctx, config)

        local notification, entries = {}, {}
        local num_files, num_updates = 0, 0

        -- collect changes
        if result.documentChanges then
          for _, document in pairs(result.documentChanges) do
            num_files = num_files + 1
            local uri = document.textDocument.uri
            local bufnr = vim.uri_to_bufnr(uri)

            for _, edit in ipairs(document.edits) do
              local start_line = edit.range.start.line + 1
              local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]

              table.insert(entries, {
                bufnr = bufnr,
                lnum = start_line,
                col = edit.range.start.character + 1,
                text = line,
              })
            end

            num_updates = num_updates + vim.tbl_count(document.edits)

            local short_uri = string.sub(vim.uri_to_fname(uri), #vim.loop.cwd() + 2)
            table.insert(notification, string.format("\t- %d in %s", vim.tbl_count(document.edits), short_uri))
          end
        end

        -- collect changes
        if result.changes then
          for uri, edits in pairs(result.changes) do
            num_files = num_files + 1
            local bufnr = vim.uri_to_bufnr(uri)

            for _, edit in ipairs(edits) do
              local start_line = edit.range.start.line + 1
              local line = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1]

              table.insert(entries, {
                bufnr = bufnr,
                lnum = start_line,
                col = edit.range.start.character + 1,
                text = line,
              })
            end

            num_updates = num_updates + vim.tbl_count(edits)

            local short_uri = string.sub(vim.uri_to_fname(uri), #vim.loop.cwd() + 2)
            table.insert(notification, string.format("\t- %d in %s", vim.tbl_count(edits), short_uri))
          end
        end

        -- format notification header and content
        local notification_str = ""
        if num_files > 1 then
          -- add header
          table.insert(
            notification,
            1,
            string.format("made %d change%s in %d files", num_updates, (num_updates > 1 and "s") or "", num_files)
          )

          notification_str = table.concat(notification, "\n")
        else
          -- only 1 entry in notification table for the single file
          notification_str = string.format("made %s", notification[1]:sub(4))

          -- add word "change"/"changes" at this point
          local insert_loc = notification_str:find("in")

          notification_str = table.concat({
            notification_str:sub(1, insert_loc - 1),
            string.format("change%s ", (num_updates > 1 and "s") or ""),
            notification_str:sub(insert_loc),
          }, "")
        end

        -- vim.notify(notification_str, L.INFO, {
        --   title = string.format("[LSP] rename: %s -> %s", position_params.oldName, position_params.newName),
        --   timeout = 2500,
        -- })

        -- set qflist if more than 1 file
        if num_files > 1 then require("mega.utils").qf_populate(entries, { title = "Applied Changes" }) end
      end)
    end

    local function prepare_rename()
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

      imap("<CR>", rename_callback, { buffer = bufnr })
      imap("<esc>", function() cleanup_rename_callback(winnr) end, { buffer = bufnr })
      imap("<c-c>", function() cleanup_rename_callback(winnr) end, { buffer = bufnr })

      vim.cmd("startinsert")
    end

    prepare_rename()
    -- vim.ui.input({ prompt = "rename to -> ", default = position_params.oldName }, rename_callback)
  end

  vim.lsp.buf.rename = qf_rename
end

function M.rename()
  local rename_prompt = ""
  local default_rename_prompt = " -> "
  local current_name = ""

  local function cleanup_rename_callback(winnr)
    api.nvim_win_close(winnr or 0, true)
    api.nvim_feedkeys(vim.keycode("<Esc>"), "i", true)

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

  local function prepare_rename()
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

  prepare_rename()
end

---@param data { old_name: string, new_name: string }
local function prepare_file_rename(data)
  local bufnr = fn.bufnr(data.old_name)
  for _, client in pairs(lsp.get_clients({ bufnr = bufnr })) do
    local rename_path = { "server_capabilities", "workspace", "fileOperations", "willRename" }
    if not vim.tbl_get(client, rename_path) then
      return vim.notify(fmt("%s does not LSP file rename", client.name), L.INFO, { title = "LSP" })
    end
    local params = {
      files = { { newUri = "file://" .. data.new_name, oldUri = "file://" .. data.old_name } },
    }
    ---@diagnostic disable-next-line: invisible
    local resp = client.request_sync("workspace/willRenameFiles", params, 1000)
    if resp then vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding) end
  end
end

function M.rename_file()
  local old_name = api.nvim_buf_get_name(0)
  -- vim.fs.basename(old_name)
  -- nvim_buf_get_name(0)
  -- -- -> fnamemodify(':t')
  -- vim.fs.basename(vim.api.nvim_buf_get_name(0))
  vim.ui.input({ prompt = fmt("rename %s to -> ", vim.fs.basename(old_name)) }, function(name)
    if not name then return end
    local new_name = fmt("%s/%s", vim.fs.dirname(old_name), name)
    prepare_file_rename({ old_name = old_name, new_name = new_name })
    lsp.util.rename(old_name, new_name)
  end)
end

return M
