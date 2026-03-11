mega.p.mini.starter = {}

local autocmd = vim.api.nvim_create_autocmd

function mega.p.mini.starter.is_active()
  return vim.bo.filetype == "ministarter"
end

function mega.p.mini.starter.refresh()
  require("mini.starter").refresh()
end

return {
  "echasnovski/mini.starter",
  opts = function()
    local project = mega.u.fs.root({ capitalize = true })

    local item = function(name, action, section)
      return { name = name, action = action, section = section }
    end

    local items = {}

    table.insert(items, function()
      if mega.p.lazy.anything_missing() then
        return item("Install plugins", mega.p.lazy.install, project)
      else
        return nil
      end
    end)

    -- if mega.p.persistence.has_session() then
    --   table.insert(items, item("Restore session", mega.p.persistence.restore, project))
    -- end

    table.insert(items, item("Browse project", mega.p.oil.open, project))

    table.insert(items, item("Quit", "qa", project))

    local config = {
      evaluate_single = false,
      header = "",
      items = items,
    }

    return config
  end,
  config = function(_, opts)
    -- close Lazy and re-open when starter is ready
    if vim.o.filetype == "lazy" then
      vim.cmd.close()
      autocmd("User", {
        pattern = "MiniStarterOpened",
        callback = function()
          require("lazy").show()
        end,
      })
    end

    local starter = require("mini.starter")

    starter.setup(opts)

    local starter_bufid

    autocmd("User", {
      pattern = "MiniStarterOpened",
      callback = function()
        -- Hide statusline elements if lualine integration exists
        if mega.p.lualine and mega.p.lualine.hide_everything then
          mega.p.lualine.hide_everything()
        end

        starter_bufid = vim.api.nvim_get_current_buf()

        autocmd("BufWipeout", {
          callback = function(args)
            -- Restore statusline when starter is closed
            if args.buf == starter_bufid then
              if mega.p.lualine and mega.p.lualine.show_everything then
                mega.p.lualine.show_everything()
              end
              starter_bufid = nil
            end
          end,
        })
      end,
    })

    autocmd("User", {
      once = true,
      pattern = "LazyVimStarted",
      callback = function(ev)
        local stats = require("lazy").stats()
        local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
        starter.config.footer = "  in " .. ms .. "ms"
        if vim.bo[ev.buf].filetype == "ministarter" then
          pcall(starter.refresh)
        end
      end,
    })

    autocmd("User", {
      once = true,
      pattern = "LazyInstall",
      callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        if ft == "ministarter" then
          pcall(starter.refresh)
        elseif ft == "lazy" then
          local ok, is_loaded = pcall(vim.api.nvim_buf_is_loaded, starter_bufid)
          if ok and is_loaded then
            pcall(function()
              starter.refresh(starter_bufid)
            end)
          end
        end
      end,
    })
  end,
}
