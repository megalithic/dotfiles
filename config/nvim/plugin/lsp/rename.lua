local M = {}
local BORDER_STYLE = vim.g.border

-- populate qf list with changes (if multiple files modified)
-- TODO: possible rewrite to this: https://github.com/mcauley-penney/nvim/blob/main/lua/aucmd/rename.lua
function M.rename(client)
  local rename_prompt = ""
  local default_rename_prompt = " -> "
  local current_name = ""

  local pos_params = vim.lsp.util.make_position_params(0, "utf-8")
  pos_params.oldName = vim.fn.expand("<cword>")
  pos_params.context = { includeDeclaration = true }

  local function cleanup_cb(winnr)
    vim.api.nvim_win_close(winnr or 0, true)
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "i", true)

    current_name = ""
    rename_prompt = default_rename_prompt
  end

  local function rename_cb(client, winnr, bufnr)
    local input = vim.trim(vim.fn.getline("."):sub(#rename_prompt, -1))

    if input == nil then
      vim.notify("aborted", L.WARN, { title = "[lsp] rename" })
      return
    elseif input == pos_params.oldName then
      vim.notify("input text matches current text; try again.", L.WARN, { title = "[lsp] rename" })
      return
    end

    pos_params.newName = input

    if
      not client:supports_method("textDocument/rename") or not client:supports_method("textDocument/prepareRename")
    then
      require("grug-far").open({ prefills = { search = pos_params.oldName, replacement = pos_params.newName } })
      vim.schedule(function()
        cleanup_cb(winnr)
      end)
      return
    else
      cleanup_cb(winnr)
    end

    vim.lsp.buf_request(0, "textDocument/rename", pos_params, function(err, result, ctx, config)
      -- result not provided, error at lsp end
      -- no changes made
      if not result or not result.changes then
        vim.notify(
          string.format("could not perform rename: %s -> %s", pos_params.oldName, pos_params.newName),
          L.ERROR,
          { title = "[lsp] rename", timeout = 500 }
        )
        return
      end

      -- apply changes
      vim.lsp.handlers["textDocument/rename"](err, result, ctx, config)

      local notification, entries = {}, {}
      local num_files, num_updates = 0, 0

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
        if insert_loc ~= nil then
          notification_str = table.concat({
            notification_str:sub(1, insert_loc - 1),
            string.format("change%s ", (num_updates > 1 and "s") or ""),
            notification_str:sub(insert_loc),
          }, "")

          vim.notify(notification_str, L.INFO, {
            title = string.format("[LSP] rename: %s -> %s", pos_params.oldName, pos_params.newName),
            timeout = 2500,
          })
        end
      end

      -- set qflist if more than 1 file
      if num_files > 1 then
        -- U.qflist_populate(entries, { title = "Applied Rename Changes" })
        vim.cmd.Trouble("qflist open focus=true")
      end
    end)
  end

  local function prepare_rename(client)
    current_name = vim.fn.expand("<cword>")
    rename_prompt = current_name .. default_rename_prompt
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
    vim.api.nvim_set_option_value("buftype", "prompt", { buf = bufnr })
    vim.api.nvim_set_option_value("filetype", "prompt", { buf = bufnr })
    -- vim.api.nvim_set_hl(bufnr, 'GitSignsAddCul', { link = 'GitSignsAddCursorLine' })
    vim.api.nvim_buf_add_highlight(bufnr, -1, "Title", 0, 0, #rename_prompt)
    vim.fn.prompt_setprompt(bufnr, rename_prompt)
    local width = #current_name + #rename_prompt + 15
    local winnr = vim.api.nvim_open_win(bufnr, true, {
      relative = "cursor",
      width = width,
      height = 1,
      row = -3,
      col = 1,
      style = "minimal",
      border = BORDER_STYLE,
    })

    vim.api.nvim_set_option_value(
      "winhl",
      table.concat({
        "Normal:NormalFloat",
        "FloatBorder:FloatBorder",
        "CursorLine:Visual",
        "Search:None",
      }, ","),
      { win = winnr }
    )

    vim.keymap.set("i", "<CR>", function()
      rename_cb(client, winnr, bufnr)
    end, { buffer = bufnr })
    vim.keymap.set("i", "<esc>", function()
      cleanup_cb(winnr)
    end, { buffer = bufnr })
    vim.keymap.set("i", "<c-c>", function()
      cleanup_cb(winnr)
    end, { buffer = bufnr })

    vim.cmd.startinsert()
  end

  prepare_rename(client)
end

return function(client)
  -- local params = vim.lsp.util.make_position_params(0, "utf-8")

  -- client.request("textDocument/references", params, function(_, result)
  --   if not result or vim.tbl_isempty(result) then
  --     vim.notify("nothing to rename.")
  --     return
  --   end
  -- end)

  M.rename(client)
end
