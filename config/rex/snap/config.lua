-- Hints mode settings (snap/hints.lua). Runs in the overlay's Neovim, so open
-- functions are Neovim Lua. Patterns are Vim regexes; use \v and %(...) for
-- groups that only alternate, since group = N copies submatch N instead.
--
-- open, per pattern:
--   nil              /usr/bin/open <match>
--   false            copy only
--   "path/to/script" run the script with the match as its argument
--   function(match, ctx) ... end, where ctx = { name, cwd, session, block }
-- path = true resolves the match against the pane's working directory first.
-- These patterns go before the built-in ones (code, url, email, fileline,
-- path, filename, uuid, sha, npi, phone) and win a tie, so a copy of a
-- built-in pattern with its own open replaces that type's handler.
return {
  patterns = {
    -- rx UXIDs, <prefix>-<Crockford base32>, from the `field :uxid, UXID,
    -- prefix: ...` schemas. Copy only for now. To open an admin page instead:
    --   open = function(match)
    --     vim.system({ "/usr/bin/open", "https://<admin host>/<path>/" .. match }, { detach = true })
    --   end,
    {
      name = "uxid",
      pattern = [[\v<%(prc|pha|pat|ppat|rx|lot|fill|order|medsup|nsup|ncon|ndel|npref)-[0-9a-hjkmnp-tv-z]{16,26}>]],
      open = false,
    },
  },
  -- Foreground colours agent TUIs give inline code, which they draw without
  -- backticks: Pi's theme, Claude Code. Find one with
  -- `rex capture --format=html` and look at the span's color.
  inline_code = { "#a798d7", "#b1b9f9" },
}
