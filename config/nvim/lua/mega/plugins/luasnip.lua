-- REF:
-- - https://github.com/chrisgrieser/dotfiles/blob/main/.config/nvim/lua/snippets.lua
-- - https://github.com/dcampos/nvim-snippy
-- - https://github.com/sbulav/dotfiles/blob/master/nvim/lua/config/snippets.lua
local M = {
  "L3MON4D3/LuaSnip",
  enabled = vim.g.snipper == "luasnip",
  event = { "InsertEnter" },
  dependencies = {
    "rafamadriz/friendly-snippets",
    event = { "InsertEnter" },
    enabled = vim.g.snipper == "luasnip",
    config = function() require("luasnip.loaders.from_vscode").lazy_load() end,
  },
}

function M.config()
  local ls = require("luasnip")
  local add = ls.add_snippets
  local snip = ls.parser.parse_snippet -- lsp-style-snippets for future-proofness
  local t = vim.keycode
  local types = require("luasnip.util.types")
  local extras = require("luasnip.extras")
  local fmt = require("luasnip.extras.fmt").fmt

  mega.augroup("LuasnipDiagnostics", {
    {
      event = { "ModeChanged" },
      pattern = { "[is]:n" },
      command = function()
        if ls.in_snippet() then return vim.diagnostic.enable() end
      end,
    },
    {
      event = { "ModeChanged" },
      pattern = { "*:s" },
      command = function()
        if ls.in_snippet() then return vim.diagnostic.disable() end
      end,
    },
  })

  ls.config.set_config({
    history = true,
    region_check_events = "CursorMoved,CursorHold,InsertEnter",
    delete_check_events = "InsertLeave",
    ext_opts = {
      [types.choiceNode] = {
        active = {
          hl_mode = "combine",
          virt_text = { { "●", "Operator" } },
        },
      },
      [types.insertNode] = {
        active = {
          hl_mode = "combine",
          virt_text = { { "●", "Type" } },
        },
      },
    },
    enable_autosnippets = true,
    snip_env = {
      fmt = fmt,
      m = extras.match,
      t = ls.text_node,
      f = ls.function_node,
      c = ls.choice_node,
      d = ls.dynamic_node,
      i = ls.insert_node,
      l = extras.lamda,
      snippet = ls.snippet,
    },
  })

  -- TODO: we want to do our own luasnippets .. se this link for more details of
  -- how we might want to do this: https://youtu.be/Dn800rlPIho

  mega.command("LuaSnipEdit", function() require("luasnip.loaders.from_lua").edit_snippet_files() end)

  --- <tab> to jump to next snippet's placeholder
  local function on_tab() return ls.jump(1) and "" or t("<Tab>") end

  --- <s-tab> to jump to next snippet's placeholder
  local function on_s_tab() return ls.jump(-1) and "" or t("<S-Tab>") end

  local opts = { expr = true, remap = true }
  imap("<Tab>", on_tab, opts)
  smap("<Tab>", on_tab, opts)
  imap("<S-Tab>", on_s_tab, opts)
  smap("<S-Tab>", on_s_tab, opts)

  --------------------------------------------------------------------------------
  -- SNIPPETS
  ls.cleanup() -- clears all snippets for writing snippets

  -- add("all", {
  --   snip({ trig = "!!", wordTrig = false }, "{\n\t$0\n\\}"),
  -- }, { type = "autosnippets" })

  add("all", {
    snip("modeline", "vim: filetype=bash"),
  })

  -- Shell (zsh)
  add("zsh", {
    snip("##", "#!/usr/bin/env zsh\n$0"),
    snip("PATH", "export PATH=/usr/local/lib:/usr/local/bin:/opt/homebrew/bin/:\\$PATH\n$0"),
    snip("resolve home", "${1:path}=\"${${1:path}/#\\~/\\$HOME}\""),
    snip("filename", "${1:file_name}=$(basename \"$${1:filepath}\")"),
    snip("parent folder", "$(dirname \"$${1:filepath}\")"),
    snip("extension", "${2:ext}=\\${${1:file_name}##*.}"),
    snip("filename w/o ext", "${1:file_name}=\\${${1:file_name}%.*}"),
    snip("directory of script", "cd \"$(dirname \"\\$0\")\"\n$0"),

    snip("if (short)", "[[ \"$${1:var}\" ]] && $0"),
    snip("if", "if [[ \"$${1:var}\" ]] ; then\n\t$0\nfi"),
    snip("if else", "if [[ \"$${1:var}\" ]] ; then\n\t$2\nelse\n\t$0\nfi"),
    snip("installed", "which ${1:cli} &> /dev/null || echo \"${1:cli} not installed.\" && exit 1"),

    snip("stderr (pipe)", "2>&1 "),
    snip("null (pipe)", "&> /dev/null "),
    snip("sed (pipe)", "| sed 's/${1:pattern}/${2:replacement}/g'"),

    snip(
      "plist extract key",
      "plutil -extract name.childkey xml1 -o - example.plist | sed -n 4p | cut -d\">\" -f2 | cut -d\"<\" -f1"
    ),
    snip("running process", "pgrep -x \"$${1:process}\" > /dev/null && $0"),
    snip("quicklook", "qlmanage -p \"${1:filepath}\""), -- mac only
    snip("sound", "afplay \"/System/Library/Sounds/${1:Submarine}.aiff\""), -- mac only

    snip("reset", "\\033[0m"),
    snip("black", "\\033[1;30m"),
    snip("red", "\\033[1;31m"),
    snip("green", "\\033[1;32m"),
    snip("yellow", "\\033[1;33m"),
    snip("blue", "\\033[1;34m"),
    snip("magenta", "\\033[1;35m"),
    snip("cyan", "\\033[1;36m"),
    snip("white", "\\033[1;37m"),
    snip("black bg", "\\033[1;40m"),
    snip("red bg", "\\033[1;41m"),
    snip("green bg", "\\033[1;42m"),
    snip("yellow bg", "\\033[1;43m"),
    snip("blue bg", "\\033[1;44m"),
    snip("magenta bg", "\\033[1;45m"),
    snip("cyan bg", "\\033[1;46m"),
    snip("white bg", "\\033[1;47m"),
  })

  add("lua", {
    snip("resolve home", "os.getenv(\"HOME\")"),
    snip(
      "for",
      [[
		for i=1, #${1:array} do
			$0
		end
	]]
    ),
    snip(
      "augroup & autocmd",
      [[
		augroup("${1:groupname}", {\})
		autocmd("${2:event}", {
			group = "${1:groupname}",
			callback = function()
				$0
			end
		})
	]]
    ),
  })

  -- AppleScript
  add("applescript", {
    snip(
      "browser URL",
      "tell application \"Brave Browser\" to set currentTabUrl to URL of active tab of front window\n$0"
    ),
    snip(
      "browser tab title",
      "tell application \"Brave Browser\" to set currentTabName to title of active tab of front window\n$0"
    ),
    snip("notify", "display notification \"${2:subtitle}\" with title \"${1:title}\"\n$0"),
    snip("##", "#!/usr/bin/env osascript\n$0"),
    snip(
      "resolve home",
      [[
		set unresolved_path to "~/Documents"
		set AppleScript's text item delimiters to "~/"
		set theTextItems to every text item of unresolved_path
		set AppleScript's text item delimiters to (POSIX path of (path to home folder as string))
		set resolved_path to theTextItems as string
		$0
	]]
    ),
  })

  -- Alfred AppleScript
  add("applescript", {
    snip("Get Alfred Env Var", "set ${1:envvar} to (system attribute \"${1:envvar}\")"),
    snip(
      "Get Alfred Env Var (Unicode Fix)",
      "set ${1:envvar} to do shell script \"echo \" & quoted form of (system attribute \"${1:envvar}\") & \" | iconv -f UTF-8-MAC -t MACROMAN\"\n$0"
    ),
    snip(
      "Set Alfred Env Var",
      "tell application id \"com.runningwithcrayons.Alfred\" to set configuration \"${1:envvar}\" to value ${2:value} in workflow (system attribute \"alfred_workflow_bundleid\")\n$0"
    ),
  })

  -- Markdown
  add("markdown", {
    snip("github note", "> __Note__  \n> $0"),
    snip("github warning", "> __Warning__  \n> $0"),
  })

  -- JavaScript (General)
  add("javascript", {
    snip({ trig = ".rr", wordTrig = false }, ".replace(/${1:regexp}/${2:flags}, \"${3:replacement}\");"),
  }, { type = "autosnippets" })

  add("javascript", {
    snip("ternary", "${1:cond} ? ${2:then} : ${3:else}"),
  })

  -- JXA-specific
  add("javascript", {
    snip("##", "#!/usr/bin/env osascript -l JavaScript\n$0"),
    snip("app", "const app = Application.currentApplication();\napp.includeStandardAdditions = true;\n$0"),
    snip("shell script", "app.doShellScript('${1:shellscript}');\n$0"),
    snip(
      "resolve home (JXA)",
      "const ${1:vari} = $.getenv(\"${2:envvar}\").replace(/^~/, app.pathTo(\"home folder\"));"
    ),
  })

  -- Alfred JXA
  add("javascript", {
    snip(
      "Set Alfred Env Var)",
      [[
		function setEnvVar(envVar, newValue) {
			Application("com.runningwithcrayons.Alfred")
				.setConfiguration(envVar, {
					toValue: newValue,
					inWorkflow: $.getenv("alfred_workflow_bundleid"),
					exportable: false
				});
		}
		$0
	]]
    ),
  })

  -- YAML
  add("yaml", {
    snip("delay (Karabiner)", "- key_code: vk_none\n  hold_down_milliseconds: 50\n"),
  })

  -- Ruby
  add("ruby", {
    -- snip("do", "do\n\t$0\nend"),
  })

  -- Elixir
  add("elixir", {
    snip("do", "do\n\t$0\nend"),
  })

  --------------------------------------------------------------------------------
  -- needs to come after snippet definitions
  ls.filetype_extend("typescript", { "javascript" }) -- typescript uses all javascript snippets
  ls.filetype_extend("bash", { "zsh" })
  ls.filetype_extend("ruby", { "rails" })

  require("luasnip.loaders.from_lua").lazy_load()
  -- NOTE: the loader is called twice so it picks up the defaults first then my
  -- snippets. @see: https://github.com/L3MON4D3/LuaSnip/issues/364
  -- require("luasnip.loaders.from_vscode").lazy_load()
  -- require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
end

return M
