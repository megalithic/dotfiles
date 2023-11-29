-- REF:
-- running tests in iex:
-- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar

vim.cmd([[setlocal iskeyword+=!,?,-]])
vim.cmd([[setlocal indentkeys-=0{]])
vim.cmd([[setlocal indentkeys+=0=end]])

-- nnoremap("<leader>ed", [[orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>]])
nnoremap("<localleader>ep", [[o|><ESC>a]])
nnoremap("<localleader>ed", [[o|> dbg()<ESC>a]])
nnoremap("<localleader>ei", [[o|> IO.inspect()<ESC>i]])
nnoremap("<localleader>eil", [[o|> IO.inspect(label: "")<ESC>hi]])

local has_wk, wk = pcall(require, "which-key")
if has_wk then wk.register({
  ["<localleader>e"] = { name = "+elixir" },
}) end

vim.cmd.iabbrev([[ep      |>]])
vim.cmd.iabbrev([[epry    require IEx; IEx.pry]])
vim.cmd.iabbrev([[ei      IO.inspect()<ESC>i]])
vim.cmd.iabbrev([[eputs   IO.puts()<ESC>i]])
vim.cmd.iabbrev([[edb      dbg()<ESC>i]])
vim.cmd.iabbrev([[~H      ~H""""""<ESC>2hi<CR><ESC>O<BS> ]])
vim.cmd.iabbrev([[~h      ~H""""""<ESC>2hi<CR><ESC>O<BS> ]])
vim.cmd.iabbrev([[:skip:  @tag :skip]])
vim.cmd.iabbrev([[tskip   @tag :skip]])

-- nnoremap("<localleader>eok", [[o|> IO.inspect(label: "")<ESC>hi]])
-- nnoremap("<localleader>eer", [[o|> IO.inspect(label: "")<ESC>hi]])
vim.cmd([[
" Wrap word in {:ok, word} tuple
nmap <silent> <localleader>ok :lua require("mega.utils").wrap_cursor_node("{:ok, ", "}")<CR>
xmap <silent> <localleader>ok :lua require("mega.utils").wrap_selected_nodes("{:ok, ", "}")<CR>


" Wrap word in {:error, word} tuple
nmap <silent> <localleader>er :lua require("mega.utils").wrap_cursor_node("{:error, ", "}")<CR>
xmap <silent> <localleader>er :lua require("mega.utils").wrap_selected_nodes("{:error, ", "}")<CR>
]])

local function desk_cmd()
  local deskfile_cmd = ""
  local deskfile_path = require("mega.utils").root_has_file("Deskfile")
  if deskfile_path then deskfile_cmd = "eval $(desk load); " end
  return deskfile_cmd
end

-- REF:
-- https://github.com/mhanberg/elixir.nvim/tree/main/lua/elixir/mix
local function root_dir(fname)
  local lsputil = require("lspconfig.util")
  local uv = vim.uv

  if not fname or fname == "" then fname = vim.fn.getcwd() end

  local path = lsputil.path
  local child_or_root_path = lsputil.root_pattern({ "mix.exs", ".git" })(fname)
  local maybe_umbrella_path =
    lsputil.root_pattern({ "mix.exs" })(uv.fs_realpath(path.join({ child_or_root_path, ".." })))

  local has_ancestral_mix_exs_path = vim.startswith(child_or_root_path, path.join({ maybe_umbrella_path, "apps" }))
  if maybe_umbrella_path and not has_ancestral_mix_exs_path then maybe_umbrella_path = nil end

  path = maybe_umbrella_path or child_or_root_path or uv.os_homedir()

  return path
end

local mix_exs_path_cache = nil

local function refresh_completions()
  local cmd = desk_cmd() .. "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""

  vim.g.mix_complete_list = vim.fn.system(cmd)

  vim.notify("commands refreshed", vim.log.levels.INFO, { title = "elixir mix" })
end

local function load_completions(cli_input)
  local l = #(vim.split(cli_input, " "))

  -- Don't print if command already selected
  if l > 2 then return "" end

  -- Use cache if list has been already loaded
  if vim.g.mix_complete_list then return vim.g.mix_complete_list end

  refresh_completions()

  return vim.g.mix_complete_list
end

local function run_mix(action, args)
  local args_as_str = table.concat(args, " ")

  local cd_cmd = ""
  local mix_exs_path = root_dir(vim.fn.expand("%:p"))

  if mix_exs_path then cd_cmd = table.concat({ "cd", mix_exs_path, "&&" }, " ") end

  local cmd = { cd_cmd, desk_cmd(), "mix", action, args_as_str }

  return vim.fn.system(table.concat(cmd, " "))
end

function __Elixir_Mix_complete(_, line, _) return load_completions(line) end

local function build_and_run_mix_cmd(opts)
  local action = opts.cmd
  local args = opts.args

  local result = run_mix(action, args)
  print(result)
end

local function load_cmd(start_line, end_line, count, cmd, ...)
  local args = { ... }

  if not cmd then return end

  local user_opts = {
    start_line = start_line,
    end_line = end_line,
    count = count,
    cmd = cmd,
    args = args,
  }

  build_and_run_mix_cmd(user_opts)
end

local function setup_mix()
  for _, cmd in pairs({ "M", "Mix" }) do
    mega.command(
      cmd,
      function(opts) load_cmd(opts.line1, opts.line2, opts.count, unpack(opts.fargs)) end,
      { range = true, nargs = "*", complete = "custom,v:lua.__Elixir_Mix_complete" }
    )
  end
end

-- setup_mix()

-- local function is_elixir_test_file()
--   local file_name = vim.fn.expand("%:t")
--   local is_test_file = type(file_name:match("_test%.exs$")) == "string" and file_name:match("_test%.exs$") ~= nil
--   return is_test_file
-- end
--
-- local function set_iex_strategy_after_delay()
--   vim.defer_fn(function()
--     local ok, neotest = pcall(require, "neotest")
--     if ok then
--       local cwd = vim.loop.cwd()
--       neotest.setup_project(cwd, {
--         adapters = { require("neotest-elixir") },
--         default_strategy = "iex",
--       })
--     end
--   end, 100)
-- end

-- if is_elixir_test_file() then set_iex_strategy_after_delay() end
