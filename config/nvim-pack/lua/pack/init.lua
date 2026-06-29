local M = {}

local GH = function(repo) return "https://github.com/" .. repo end

-- Local dev plugins: repos owned by these patterns load from ~/code/oss/<repo>
-- when present, falling back to git otherwise. Mirrors lazy.nvim `dev` config.
local dev_path = vim.fn.expand("~/code/oss")
local dev_patterns = { "megalithic" }

local function dev_src(repo)
  if type(repo) ~= "string" then return nil end
  local owner = repo:match("^([^/]+)/")
  if not owner then return nil end
  local matched = false
  for _, pat in ipairs(dev_patterns) do
    if owner == pat then matched = true break end
  end
  if not matched then return nil end
  local name = repo:gsub("%.git$", ""):match("([^/]+)$")
  local localdir = dev_path .. "/" .. name
  if vim.uv.fs_stat(localdir) then return localdir end
  return nil -- fallback to git
end

local spec_modules = {
  "plugins",
  "plugins.ai",
  "plugins.autopairs",
  "plugins.blink",
  "plugins.codediff",
  "plugins.debug",
  "plugins.firenvim",
  "plugins.flash",
  "plugins.genghis",
  "plugins.git",
  "plugins.github",
  "plugins.grug_far",
  "plugins.jj",
  "plugins.lsp",
  "plugins.lsp.conform",
  "plugins.lsp.dropbar",
  "plugins.lsp.trouble",
  "plugins.lush",
  "plugins.mini",
  "plugins.mini.ai",
  "plugins.mini.clue",
  "plugins.mini.diff",
  "plugins.mini.pairs",
  "plugins.mini.surround",
  "plugins.noice",
  "plugins.obsidian",
  "plugins.oil",
  "plugins.refer",
  "plugins.snacks",
  "plugins.test",
  "plugins.treesitter",
  "plugins.treesj",
  "plugins.whichkey",
}

local setup_name_overrides = {
  ["nvim-autopairs"] = "nvim-autopairs",
  ["blink.cmp"] = "blink.cmp",
  ["blink.pairs"] = "blink.pairs",
  ["colorful-menu.nvim"] = "colorful-menu",
  ["gitsigns.nvim"] = "gitsigns",
  ["conform.nvim"] = "conform",
  ["dropbar.nvim"] = "dropbar",
  ["trouble.nvim"] = "trouble",
  ["grug-far.nvim"] = "grug-far",
  ["oil.nvim"] = "oil",
  ["noice.nvim"] = "noice",
  ["which-key.nvim"] = "which-key",
  ["mini.ai"] = "mini.ai",
  ["mini.clue"] = "mini.clue",
  ["mini.diff"] = "mini.diff",
  ["mini.jump"] = "mini.jump",
  ["mini.jump2d"] = "mini.jump2d",
  ["mini.pairs"] = "mini.pairs",
  ["mini.surround"] = "mini.surround",
  ["snacks.nvim"] = "snacks",
  ["fff.nvim"] = "fff",
  ["fff-snacks.nvim"] = "fff-snacks",
  ["tiny-inline-diagnostic.nvim"] = "tiny-inline-diagnostic",
  ["tiny-code-action.nvim"] = "tiny-code-action",
  ["output-panel.nvim"] = "output_panel",
  ["nvim-treesitter-context"] = "treesitter-context",
  ["nvim-ts-autotag"] = "nvim-ts-autotag",
  ["tssorter.nvim"] = "tssorter",
  ["treesj"] = "treesj",
  ["render-markdown.nvim"] = "render-markdown",
  ["lazydev.nvim"] = "lazydev",
  ["mdn.nvim"] = "mdn",
  ["markdown.nvim"] = "markdown",
  ["iex.nvim"] = "iex",
  ["jiejie.nvim"] = "jj",
  ["hunk.nvim"] = "hunk",
  ["codediff.nvim"] = "codediff",
  ["annotator.nvim"] = "annotator",
  ["nvim-dap-ui"] = "dapui",
  ["nvim-dap-virtual-text"] = "nvim-dap-virtual-text",
  ["nvim-genghis"] = "genghis",
  ["prompt-yank.nvim"] = "prompt-yank",
}

local disabled_runtime = {
  "gzip",
  "matchit",
  "matchparen",
  "netrwPlugin",
  "rplugin",
  "tarPlugin",
  "tohtml",
  "tutor",
  "zipPlugin",
}

local function should_enable(spec)
  if spec.enabled == false then return false end
  if type(spec.enabled) == "function" then
    local ok, enabled = pcall(spec.enabled)
    if not ok or not enabled then return false end
  end
  if spec.cond == false then return false end
  if type(spec.cond) == "function" then
    local ok, cond = pcall(spec.cond)
    if not ok or not cond then return false end
  end
  return true
end

local function repo_name(repo)
  if type(repo) ~= "string" then return nil end
  local name = repo:gsub("%.git$", ""):match("([^/]+)$")
  return name
end

local function main_name(spec)
  if spec.main then return spec.main end
  local name = spec.name or repo_name(spec[1] or spec.src)
  if setup_name_overrides[name] then return setup_name_overrides[name] end
  if not name then return nil end
  name = name:gsub("%.nvim$", ""):gsub("^nvim%-", ""):gsub("^vim%-", "")
  return name
end

local function as_pack_spec(spec)
  local repo = spec[1] or spec.src
  if type(repo) ~= "string" then return nil end

  local src = repo:match("^https?://") and repo or GH(repo)
  local out = { src = src }
  if spec.name then out.name = spec.name end
  if spec.version and spec.version ~= false and spec.version ~= "*" then out.version = spec.version end
  if spec.branch then out.version = spec.branch end
  return out
end

--- Whether a spec should load from a local dev path instead of vim.pack.
local function dev_path_for(spec)
  local repo = spec[1] or spec.src
  if type(repo) ~= "string" then return nil end
  return dev_src(repo)
end

local function normalize_list(value)
  if not value then return {} end
  if type(value) ~= "table" then return { value } end
  return value
end

local function add_spec(spec, acc, seen, idx)
  if type(spec) == "string" then spec = { spec } end
  if type(spec) ~= "table" then return end

  if (spec[1] == nil or type(spec[1]) == "table") and spec.src == nil then
    for _, child in ipairs(spec) do
      add_spec(child, acc, seen, idx)
    end
    return
  end

  if not should_enable(spec) then return end

  for _, dep in ipairs(normalize_list(spec.dependencies)) do
    add_spec(dep, acc, seen, idx)
  end

  local pack_spec = as_pack_spec(spec)
  if not pack_spec then return end
  local key = pack_spec.name or repo_name(pack_spec.src)

  local richer = spec.config ~= nil or spec.init ~= nil or spec.opts ~= nil or spec.keys ~= nil
  if seen[key] then
    -- Replace a bare dependency placeholder with the full spec when it arrives.
    if richer and not seen[key].richer then
      acc[seen[key].idx] = spec
      seen[key] = { idx = seen[key].idx, richer = true }
    end
    return
  end
  local i = #acc + 1
  acc[i] = spec
  seen[key] = { idx = i, richer = richer }
end

local function load_specs()
  local specs, seen, idx = {}, {}, nil

  for _, name in ipairs(spec_modules) do
    local ok, mod = pcall(require, name)
    if ok then add_spec(mod, specs, seen, idx) end
  end

  local ok_langs, langs = pcall(require, "langs")
  if ok_langs and langs.lazy_specs then
    add_spec(langs.lazy_specs(), specs, seen, idx)
  end

  return specs
end

local function run_init(spec)
  if type(spec.init) == "function" then pcall(spec.init) end
end

local function get_opts(spec)
  if type(spec.opts) == "function" then
    local ok, opts = pcall(spec.opts, spec)
    if ok then return opts end
    return nil
  end
  return spec.opts
end

local function setup_spec(spec)
  local opts = get_opts(spec)

  if type(spec.config) == "function" then
    pcall(spec.config, spec, opts)
    return
  end

  if spec.config == false or opts == nil then return end

  local modname = main_name(spec)
  if not modname then return end
  local ok, mod = pcall(require, modname)
  if ok and type(mod.setup) == "function" then pcall(mod.setup, opts) end
end

local function get_keys(spec)
  if type(spec.keys) == "function" then
    local ok, keys = pcall(spec.keys)
    if ok then return keys end
    return nil
  end
  return spec.keys
end

local function setup_keys(spec)
  local keys = get_keys(spec)
  if not keys then return end
  if type(keys) == "string" then return end

  for _, key in ipairs(keys) do
    if type(key) == "table" and type(key[1]) == "string" and key[2] ~= nil then
      local lhs, rhs = key[1], key[2]
      local opts = vim.tbl_extend("force", key, {})
      opts[1], opts[2] = nil, nil
      local mode = opts.mode or "n"
      opts.mode = nil
      pcall(vim.keymap.set, mode, lhs, rhs, opts)
    end
  end
end

local function packadd(plug)
  pcall(vim.cmd.packadd, plug.spec.name)
end

M.load_specs = load_specs

function M.setup()
  vim.loader.enable()

  for _, plugin in ipairs(disabled_runtime) do
    vim.g["loaded_" .. plugin] = 1
  end

  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local name, kind = ev.data.spec.name, ev.data.kind
      if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
        if not ev.data.active then pcall(vim.cmd.packadd, "nvim-treesitter") end
        pcall(vim.cmd.TSUpdate)
      elseif name == "fff.nvim" and (kind == "install" or kind == "update") then
        if ev.data.path then vim.opt.runtimepath:prepend(ev.data.path) end
        if not ev.data.active then pcall(vim.cmd.packadd, "fff.nvim") end
        pcall(function() require("fff.download").download_or_build_binary() end)
      end
    end,
  })

  local specs = load_specs()
  for _, spec in ipairs(specs) do
    run_init(spec)
  end

  -- Dev plugins load live from ~/code/oss via rtp; remote plugins via vim.pack.
  local pack_specs = {}
  for _, spec in ipairs(specs) do
    local localdir = dev_path_for(spec)
    if localdir then
      vim.opt.runtimepath:prepend(localdir)
    else
      pack_specs[#pack_specs + 1] = as_pack_spec(spec)
    end
  end

  vim.pack.add(pack_specs, { load = packadd })

  for _, spec in ipairs(specs) do
    setup_spec(spec)
  end

  for _, spec in ipairs(specs) do
    setup_keys(spec)
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
end

return M
