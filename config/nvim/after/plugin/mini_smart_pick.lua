if true then
  return nil
end

--- SmartPick - Enhanced file and buffer picker with intelligent highlighting
--- ==========================================================================
--- @author Suliatis
--- @license MIT
--- @ref https://gist.github.com/suliatis/5d59fcff490dc32b9e877a599559b05f

local MiniSmartPick = {}
local H = {}

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Initialize SmartPick by creating the highlight namespace
--- @return nil
function MiniSmartPick.setup()
  H.ns_id = vim.api.nvim_create_namespace("MiniSmartPick")
  -- _G.MiniSmartPick = MiniSmartPick
end

--- Launch the SmartPick picker interface
--- Combines buffers (by recency) and files (alphabetically) in a unified picker
--- @return nil
function MiniSmartPick.picker()
  if _G.MiniPick == nil then
    _G.MiniPick = require("mini.pick")
  end

  local picker_items = { items = {} }

  MiniPick.builtin.cli({
    command = {
      "sh",
      "-c",
      "rg --files --hidden --glob '!.git'; rg --files --no-ignore-vcs --glob '*.env'",
    },
    postprocess = function(paths)
      return H.postprocess_items(paths, picker_items)
    end,
  }, {
    source = {
      name = "MiniSmartPick",
      show = function(buf_id, items, query)
        H.show_items(buf_id, items, query, picker_items)
      end,
      choose = MiniPick.default_choose,
      match = function(stritems, inds, query)
        return H.match_items(stritems, inds, query, picker_items)
      end,
    },
  })
end

-- ============================================================================
-- SECTION: Constants
-- ============================================================================

H.GENERIC_FILENAMES = {
  ["init.lua"] = true,
  ["index.html"] = true,
  ["index.js"] = true,
  ["index.jsx"] = true,
  ["index.ts"] = true,
  ["index.tsx"] = true,
  ["main.js"] = true,
  ["main.ts"] = true,
  ["app.js"] = true,
  ["app.ts"] = true,
  ["mod.rs"] = true,
  ["lib.rs"] = true,
  ["__init__.py"] = true,
}

-- ============================================================================
-- SECTION: Buffer Management
-- ============================================================================

function H.get_recent_buffers()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  buffers = vim.tbl_filter(function(buf)
    local buftype = vim.bo[buf.bufnr].buftype

    if buftype == "quickfix" or buftype == "prompt" then
      return false
    end

    if buftype == "" then
      if buf.name == "" then
        return true
      end
      return vim.fn.filereadable(buf.name) == 1
    else
      return true
    end
  end, buffers)

  table.sort(buffers, function(a, b)
    return a.lastused > b.lastused
  end)

  return vim.tbl_map(function(buf)
    local buftype = vim.bo[buf.bufnr].buftype
    local is_file = buftype == ""
    local text = is_file and vim.fn.fnamemodify(buf.name, ":.") or buf.name
    return { text = text, bufnr = buf.bufnr, type = "buffer", is_file = is_file }
  end, buffers)
end

-- ============================================================================
-- SECTION: File Operations
-- ============================================================================

function H.deduplicate_files(buffers, files)
  local seen = {}
  for _, buf in ipairs(buffers) do
    seen[buf.text] = true
  end

  local deduplicated = {}
  for _, path in ipairs(files) do
    if path ~= "" then
      path = vim.fn.fnamemodify(path, ":.")
      if not seen[path] then
        table.insert(deduplicated, path)
      end
    end
  end

  table.sort(deduplicated)
  return deduplicated
end

-- ============================================================================
-- SECTION: Item Processing
-- ============================================================================

function H.get_item_text(item)
  return type(item) == "table" and item.text or item
end

function H.get_filename(path)
  return path:match("([^/]+)$") or path
end

function H.postprocess_items(paths, picker_items)
  local buffers = H.get_recent_buffers()
  local files = H.deduplicate_files(buffers, paths)

  picker_items.items = {}
  local all_items = {}

  for _, buf in ipairs(buffers) do
    table.insert(all_items, buf)
    picker_items.items[buf.text] = {
      type = "buffer",
      text = buf.text,
      bufnr = buf.bufnr,
      is_file = buf.is_file,
    }
  end

  for _, file in ipairs(files) do
    table.insert(all_items, file)
    picker_items.items[file] = {
      type = "file",
      text = file,
      is_file = true,
    }
  end

  return all_items
end

-- ============================================================================
-- SECTION: Highlighting
-- ============================================================================

function H.calculate_path_highlight_end(text)
  local last_slash = text:match(".*()/")
  if not last_slash or last_slash <= 1 then
    return nil
  end

  local filename = text:sub(last_slash + 1)
  if H.GENERIC_FILENAMES[filename] then
    local path_without_filename = text:sub(1, last_slash - 1)
    local second_last_slash = path_without_filename:match(".*()/")
    if second_last_slash and second_last_slash > 1 then
      return second_last_slash - 1
    end
    return nil
  else
    return last_slash - 1
  end
end

function H.apply_path_highlights(buf_id, line_nr, text, line_content)
  local dir_end_pos = H.calculate_path_highlight_end(text)
  if not dir_end_pos then
    return nil
  end

  local icon_end = line_content:find(text, 1, true) or 1
  local dir_start = icon_end - 1
  local dir_end = icon_end + dir_end_pos - 1

  vim.api.nvim_buf_set_extmark(buf_id, H.ns_id, line_nr, dir_start, {
    end_col = dir_end,
    hl_group = "SmartPickPath",
    priority = 50,
  })

  return { icon_end = icon_end, dir_end_pos = dir_end_pos, dir_start = dir_start, dir_end = dir_end }
end

function H.apply_match_highlights_in_path(buf_id, line_nr, text, query, path_info)
  if not query or #query == 0 or not path_info then
    return
  end

  local query_str = table.concat(query):lower()
  local path_portion = text:sub(1, path_info.dir_end_pos):lower()

  local search_start = 1
  while true do
    local match_start, match_end = path_portion:find(query_str, search_start, true)
    if not match_start then
      break
    end

    local abs_start = path_info.icon_end - 1 + match_start - 1
    local abs_end = path_info.icon_end - 1 + match_end

    if abs_start >= path_info.dir_start and abs_end <= path_info.dir_end then
      vim.api.nvim_buf_set_extmark(buf_id, H.ns_id, line_nr, abs_start, {
        end_col = abs_end,
        hl_group = "SmartPickPathMatch",
        priority = 200,
      })
    end

    search_start = match_end + 1
  end
end

function H.show_items(buf_id, items, query, picker_items)
  local MiniPick = require("mini.pick")

  MiniPick.default_show(buf_id, items, query, { show_icons = true })

  for i, item in ipairs(items) do
    local line_nr = i - 1
    local text = H.get_item_text(item)
    local item_meta = picker_items.items[text]

    if item_meta and item_meta.type == "buffer" and item_meta.is_file then
      local line_len = vim.api.nvim_buf_get_lines(buf_id, line_nr, line_nr + 1, false)[1]:len()
      vim.api.nvim_buf_set_extmark(buf_id, H.ns_id, line_nr, 0, {
        end_col = line_len,
        hl_group = "SmartPickBuffer",
        priority = 10,
      })
    end

    local is_file_path = (item_meta and item_meta.type == "file")
      or (item_meta and item_meta.type == "buffer" and item_meta.is_file)
    if is_file_path then
      local line_content = vim.api.nvim_buf_get_lines(buf_id, line_nr, line_nr + 1, false)[1] or ""
      local path_info = H.apply_path_highlights(buf_id, line_nr, text, line_content)
      H.apply_match_highlights_in_path(buf_id, line_nr, text, query, path_info)
    end
  end
end

-- ============================================================================
-- SECTION: Matching
-- ============================================================================

function H.match_items(stritems, inds, query, picker_items)
  local MiniPick = require("mini.pick")

  -- Safety checks
  if #stritems == 0 or #inds == 0 then
    return inds
  end

  -- Empty query: return all items using default behavior
  if not query or query == "" then
    return MiniPick.default_match(stritems, inds, query, { sync = true })
  end

  -- Fallback to default matching if picker_items is not properly structured
  if not picker_items or not picker_items.items then
    return MiniPick.default_match(stritems, inds, query, { sync = true })
  end

  -- Wrap in pcall for error safety
  local ok, result = pcall(function()
    -- Get items to match (only those in inds)
    local items_to_match = {}
    local idx_map = {} -- Map result index to original index

    for _, idx in ipairs(inds) do
      table.insert(items_to_match, stritems[idx])
      idx_map[#items_to_match] = idx
    end

    -- Use matchfuzzypos for fuzzy matching
    local match_result = vim.fn.matchfuzzypos(items_to_match, query)
    local matched_texts = match_result[1]
    local scores = match_result[3]

    if #matched_texts == 0 then
      return {}
    end

    -- Build scored items with our custom boosts
    local scored_items = {}
    for i, text in ipairs(matched_texts) do
      local orig_idx = nil
      -- Find original index by matching text
      for j, item in ipairs(items_to_match) do
        if item == text then
          orig_idx = idx_map[j]
          -- Remove from idx_map to handle duplicates
          idx_map[j] = nil
          break
        end
      end

      if orig_idx then
        local score = scores[i]
        local meta = picker_items.items[text]

        -- Apply boosts (higher score is better for matchfuzzypos)
        if meta and meta.type == "buffer" then
          score = score * 2 -- Double score for buffers
        end

        -- Check filename match boost
        local filename = H.get_filename(text)
        local filename_result = vim.fn.matchfuzzypos({ filename }, query)
        if #filename_result[1] > 0 then
          score = score * 3 -- Triple score for filename matches
        end

        table.insert(scored_items, { idx = orig_idx, score = score })
      end
    end

    -- Sort by score (higher is better for matchfuzzypos)
    table.sort(scored_items, function(a, b)
      if math.abs(a.score - b.score) < 0.001 then
        -- Tiebreaker: original order
        return a.idx < b.idx
      end
      return a.score > b.score -- Higher score first
    end)

    -- Return sorted indices
    return vim.tbl_map(function(item)
      return item.idx
    end, scored_items)
  end)

  if ok then
    return result
  else
    -- Fallback to default matching if anything goes wrong
    return MiniPick.default_match(stritems, inds, query, { sync = true })
  end
end

MiniSmartPick.setup()

return MiniSmartPick
