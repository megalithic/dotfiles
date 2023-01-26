-- local util = require("util")

local M = {}

function M.setup()
  local fn = vim.fn
  local api = vim.api
  local lsp = vim.lsp
  local vcmd = vim.cmd
  -- local bufmap, bmap = mega.bufmap, mega.bmap
  local lspconfig = require("lspconfig")
  local command = mega.command
  local augroup = mega.augroup
  local fmt = string.format
  local diagnostic = vim.diagnostic

  local max_width = math.min(math.floor(vim.o.columns * 0.7), 100) or 100
  local max_height = math.min(math.floor(vim.o.lines * 0.3), 30) or 30

  local opts = {
    border = mega.get_border(),
    max_width = max_width,
    max_height = max_height,
    focusable = false,
    focus = false,
    silent = true,
    severity_sort = true,
    close_events = {
      "CursorMoved",
      "BufHidden",
      "InsertCharPre",
      "BufLeave",
      "InsertEnter",
      "FocusLost",
      "BufWritePre",
      "BufWritePost",
    },
  }

  -- do
  --   local function hover_handler(_, result, _ctx, config)
  --     -- M.hover_orig(_, result, ...)
  --     if not (result and result.contents) then
  --       mega.notify("No information available", vim.log.levels.WARN)
  --       return
  --     end
  --
  --     local contents = result.contents
  --
  --     if not vim.tbl_islist(contents) then contents = { contents } end
  --
  --     local parts = {}
  --
  --     for _, content in ipairs(contents) do
  --       if type(content) == "string" then
  --         table.insert(parts, content)
  --       elseif content.language then
  --         table.insert(parts, ("```%s\n%s\n```"):format(content.language, content.value))
  --       elseif content.kind == "markdown" then
  --         table.insert(parts, content.value)
  --       elseif content.kind == "plaintext" then
  --         table.insert(parts, ("```\n%s\n```"):format(content.value))
  --       end
  --     end
  --
  --     local text = table.concat(parts, "\n")
  --     text = text:gsub("\n\n", "\n")
  --     text = text:gsub("\n%s*\n```", "\n```")
  --     text = text:gsub("```\n%s*\n", "```\n")
  --
  --     local lines = vim.split(text, "\n")
  --
  --     local width = 50
  --     for _, line in pairs(lines) do
  --       width = math.max(width, vim.api.nvim_strwidth(line))
  --     end
  --
  --     for l, line in ipairs(lines) do
  --       if line:find("^[%*%-_][%*%-_][%*%-_]+$") then lines[l] = ("─"):rep(width) end
  --     end
  --
  --     text = table.concat(lines, "\n")
  --
  --     local n_ok, notify = pcall(require, "notify")
  --     if n_ok and vim.g.notifier_enabled and vim.o.cmdheight == 0 then
  --       local open = true
  --       P("we're in a custom folke hover")
  --       notify(text, vim.log.levels.INFO, {
  --         title = "Hover",
  --         keep = function() return open end,
  --         on_open = function(win)
  --           local buf = vim.api.nvim_win_get_buf(win)
  --           vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  --           vim.api.nvim_win_set_option(win, "spell", false)
  --
  --           vim.api.nvim_create_autocmd("CursorMoved", {
  --             callback = function()
  --               open = false
  --               if not open then notify.dismiss() end
  --             end,
  --             once = true,
  --           })
  --         end,
  --       })
  --       -- else
  --       --   local bufnr = require("vim.lsp.util").open_floating_preview(lines, "markdown", config)
  --       --   -- local lines = vim.split(result.contents.value, "\n")
  --
  --       --   -- local ok, _ = pcall(require, "colorizer")
  --       --   -- if ok then
  --       --   --   require("colorizer").highlight_buffer(
  --       --   --     bufnr,
  --       --   --     nil,
  --       --   --     vim.list_slice(lines, 2, #lines),
  --       --   --     0,
  --       --   --     require("colorizer").get_buffer_options(0)
  --       --   --   )
  --       --   -- end
  --
  --       --   return bufnr
  --     end
  --   end
  --   -- local orig_hover_handler = lsp.handlers["textDocument/hover"]
  --   -- if pcall(require, "notify") == true then
  --   --   lsp.handlers["textDocument/hover"] = lsp.with(hover_handler, opts)
  --   -- else
  --   lsp.handlers["textDocument/hover"] = function(...)
  --     local handler = lsp.with(hover_handler, {
  --       border = mega.get_border(),
  --       max_width = max_width,
  --       max_height = max_height,
  --       pad_top = 2,
  --       pad_bottom = 2,
  --     })
  --     vim.b.lsp_hover_buf, vim.b.lsp_hover_win = handler(...)
  --   end
  --   -- end
  -- end

  -- local signature_help_opts = mega.table_merge(opts, {
  --   -- anchor = "SW",
  --   -- relative = "cursor",
  --   -- row = -1,
  --   border = mega.get_border(),
  --   max_width = max_width,
  --   max_height = max_height,
  -- })
  -- lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, signature_help_opts)

  lsp.handlers["window/showMessage"] = function(_, result, ctx)
    local client = lsp.get_client_by_id(ctx.client_id)
    local lvl = ({ "ERROR", "WARN", "INFO", "DEBUG", "OFF" })[result.type]
    vim.notify(result.message, vim.log.levels[lvl], {
      title = "LSP | " .. client.name,
      timeout = 8000,
      keep = function() return lvl == "ERROR" or lvl == "WARN" end,
    })
  end

  do
    if true then return end
    local nnotify_ok, nnotify = pcall(require, "notify")

    if nnotify_ok and nnotify then
      local client_notifs = {}

      local function get_notif_data(client_id, token)
        if not client_notifs[client_id] then client_notifs[client_id] = {} end

        if not client_notifs[client_id][token] then client_notifs[client_id][token] = {} end

        return client_notifs[client_id][token]
      end

      local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

      local function update_spinner(client_id, token)
        local notif_data = get_notif_data(client_id, token)

        if notif_data.spinner then
          local new_spinner = (notif_data.spinner + 1) % #spinner_frames
          notif_data.spinner = new_spinner
          notif_data.notification = nnotify(nil, nil, {
            hide_from_history = true,
            icon = spinner_frames[new_spinner],
            replace = notif_data.notification,
          })

          vim.defer_fn(function() update_spinner(client_id, token) end, 100)
        end
      end

      local function format_title(title, client_name) return client_name .. (#title > 0 and ": " .. title or "") end

      local function format_message(message, percentage)
        return (percentage and percentage .. "%\t" or "") .. (message or "")
      end

      vim.lsp.handlers["$/progress"] = function(_, result, ctx)
        local client_id = ctx.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        if
          client
          and (
            client.name == "elixirls"
            or client.name == "sumneko_lua"
            or client.name == "rust_analyzer"
            or client.name == "clangd"
            or client.name == "shellcheck"
            or client.name == "bashls"
          )
        then
          return
        end

        local val = result.value

        if not val.kind then return end

        local notif_data = get_notif_data(client_id, result.token)

        if val.kind == "begin" then
          local message = format_message(val.message, val.percentage)

          notif_data.notification = nnotify(message, "info", {
            title = format_title(val.title, vim.lsp.get_client_by_id(client_id).name),
            icon = spinner_frames[1],
            timeout = false,
            hide_from_history = false,
          })

          notif_data.spinner = 1
          update_spinner(client_id, result.token)
        elseif val.kind == "report" and notif_data then
          notif_data.notification = nnotify(format_message(val.message, val.percentage), "info", {
            replace = notif_data.notification,
            hide_from_history = false,
          })
        elseif val.kind == "end" and notif_data then
          notif_data.notification = nnotify(val.message and format_message(val.message) or "Complete", "info", {
            icon = "",
            replace = notif_data.notification,
            timeout = 3000,
          })

          notif_data.spinner = nil
        end
      end
    end
  end

  vim.lsp.util.convert_input_to_markdown_lines = function(input, contents)
    contents = contents or {}
    local ret = require("mega.utils").format_markdown(input)
    vim.list_extend(contents, ret)
    return ret
  end

  -- lsp.handlers["textDocument/definition"] = function(_, result)
  --   if result == nil or vim.tbl_isempty(result) then
  --     print("Definition not found")
  --     return nil
  --   end
  --   local function jumpto(loc)
  --     local split_cmd = vim.uri_from_bufnr(0) == loc.targetUri and "edit" or "vnew"
  --     vim.cmd(split_cmd)
  --     lsp.util.jump_to_location(loc)
  --   end
  --   if vim.tbl_islist(result) then
  --     jumpto(result[1])

  --     if #result > 1 then
  --       fn.setqflist(lsp.util.locations_to_items(result))
  --       api.nvim_command("copen")
  --       api.nvim_command("wincmd p")
  --     end
  --   else
  --     jumpto(result)
  --   end
  -- end
end

return M
