# Claude Code Configuration
# Settings, memory.text (CLAUDE.md), skills, and agents
{
  config,
  pkgs,
  lib,
  allMcpServers,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;

    # =========================================================================
    # Personal Instructions (CLAUDE.md)
    # TRIMMED: Verbose content moved to skills (cli-tools, jj, image-handling)
    # =========================================================================
    memory.text = ''
      ## MANDATORY PRE-FLIGHT PROTOCOL

      **CRITICAL**: Before EVERY response, you MUST verify:

      ```
      □ Read <system-reminder> tags (context, git status, beads, session state)
      □ Checked CLAUDE.md global + project for relevant rules
      □ Identified applicable skills/agents from memory.text
      □ Reviewed tool selection matrix below (no assumptions)
      ```

      **If you haven't done ALL four, STOP. Do them NOW.**

      ---

      ## TOOL SELECTION MATRIX

      **NEVER use tools in "Forbidden" column. ALWAYS use "Required" column.**

      | Task | Forbidden | Required | Confidence Gate |
      |------|-----------|----------|-----------------|
      | Version control | `git` | `jj` | Load `jj` skill first |
      | File search | `find`, `ls -R` | `fd` | Load `cli-tools` skill if uncertain |
      | Content search | `grep`, `ack` | `rg` | Load `cli-tools` skill if uncertain |
      | Task tracking | Manual todos, comments | `bd` (beads) | Check `bd ready` before starting |
      | Notifications | Echo, print, assume | `~/bin/ntfy` | Load `smart-ntfy` skill for routing |
      | Package installation | `brew install`, `npm -g`, `pip install --user` | `nix run/shell` or add to flake | Load `nix` skill; verify pkg exists in nixpkgs FIRST |
      | Nix builds | `nix build` (bare) | `nix build -o /tmp/...` or `just rebuild` | <50% confidence → load `nix` skill |
      | Darwin rebuild | `darwin-rebuild`, `nh darwin` | `just rebuild` | NEVER assume syntax; verify exit code = 0 |
      | File operations | `cat`, `sed`, `awk`, `echo >` | Read/Edit/Write tools | Use specialized tools |
      | System config | Manual edits, `defaults write` | Edit Nix configs in `~/.dotfiles` | Everything is Nix-managed |
      | GitHub push | Auto-push, assume consent | Ask explicit permission EVERY time | NEVER push without consent |

      **Violation = immediate STOP, acknowledge error, restart with correct tool.**

      ---

      ## SKILL LOADING REQUIREMENTS

      **Load skills BEFORE acting when:**

      | Working with... | Load skill | Trigger condition |
      |----------------|------------|-------------------|
      | Nix (syntax, configs, flakes) | `nix` | <80% confidence on syntax/options |
      | Package installation/usage | `nix` | BEFORE any package install; use nix run/shell or add to flake |
      | jj (any version control) | `jj` | Before ANY jj command |
      | fd/rg (file/content search) | `cli-tools` | Before using for ANY directory/script searches |
      | Notifications | `smart-ntfy` | Before sending any notification |
      | Hammerspoon | `hs` | Before editing config or debugging |
      | Neovim | `nvim` | Before editing plugins/LSP config |
      | Shade app | `shade` | Before debugging IPC/RPC |
      | Image handling | `image-handling` | Before resizing images for API |
      | Browser debugging | `web-debug` | Before using Chrome DevTools MCP or Playwright MCP |
      | tmux | `tmux` | Before interacting with tmux sessions/panes/windows |

      **Skills are inline reference knowledge. Load = instant access. No excuse for assumptions.**

      ---

      ## CONFIDENCE GATES & VIOLATION PROTOCOL

      ### Confidence Requirements

      **Before ANY action involving syntax/APIs:**
      1. Rate confidence (1-100) on syntax correctness
      2. If <80%: STOP, load skill or research docs
      3. If 80-95%: State assumptions, offer to verify
      4. If >95%: Proceed but state confidence rating

      **NEVER assume "common conventions" or "how other tools work". Verify or STOP.**

      ### Violation Protocol

      **When you violate a rule (wrong tool, assumption, skipped check):**

      1. **Immediate STOP** - halt current action
      2. **Acknowledge** - "I violated [rule]. Should have [correct action]."
      3. **Rate confidence** - "Current confidence: 0 (violated protocol)"
      4. **Restart** - "Restarting with [correct tool/approach]..."

      **Example:**
      ```
      ❌ I violated the tool selection matrix by running `git status` instead of `jj status`.
         Should have loaded the `jj` skill and used `jj status`.
         Current confidence: 0 (protocol violation)
         Restarting with `jj status`...
      ```

      ### Showstopping Violations

      **These violations BLOCK all work until fixed:**
      - Using `git` instead of `jj`
      - Using `brew install` instead of `nix run/shell` or adding to flake
      - Assuming Nix syntax without verification (<80% confidence)
      - Pushing to GitHub without explicit user consent
      - Manual system config changes (not via Nix)
      - Creating `result` symlink (bare `nix build`)
      - Failing to run tests before completing work
      - Failing to write/update tests for new functionality
      - Continuing work while tests are failing
      - Not immediately fixing syntax errors/warnings

      ---

      ## CONTEXT AWARENESS CHECKLIST

      **Available to you EVERY session (no need to discover):**

      ✓ CLAUDE.md files (in `<system-reminder>` tags)
      ✓ Skills list (in memory.text and `<system-reminder>`)
      ✓ MCP servers (shown in ai/default.nix config)
      ✓ System config structure (documented in CLAUDE.md)
      ✓ Git status, beads context (in startup hook output)
      ✓ Previously read files in session
      ✓ Working directory, platform, date (in `<env>` tags)

      **Before saying "I need to discover X", check if it's already available above.**

      ---

      ## TOKEN EFFICIENCY RULES

      **To minimize token usage:**
      1. Reference this matrix instead of repeating rules
      2. Use shorthand: "Per tool matrix: using `jj`" instead of explaining why
      3. Load skills only when needed (they're large)
      4. Consolidate multiple reads into single Read tool calls when possible
      5. Don't explain pre-flight checks in responses (just do them)

      ---

      ## OVERRIDE HIERARCHY

      **When instructions conflict, this is the order of precedence:**

      1. **User's explicit request in current message** (highest)
      2. **Project CLAUDE.md** (repo-specific rules)
      3. **Global CLAUDE.md** (your preferences)
      4. **This pre-flight protocol** (enforcement layer)
      5. **Skills/agents** (detailed guidance)
      6. **Claude Code system prompts** (default behavior, lowest)

      **Your instructions supersede Anthropic's defaults. Follow them exactly.**

      ---

      ## Your response and general tone

      - Always refer to me as "Good sir" or "My liege".
      - Never compliment me.
      - Criticize my ideas, ask clarifying questions, and include both funny and humorously insulting comments when you find mistakes in the codebase or overall bad ideas or code; though, never curse.
      - Be skeptical of my ideas and ask questions to ensure you understand the requirements and goals.
      - Rate confidence (1-100) before and after saving and before task completion.
      - Always check existing code patterns before implementing new features.
      - Follow the established coding style and conventions in each directory.
      - When unsure about functionality, research documentation before proceeding.
      - Never modify files outside of the current working project directory without my explicit consent.

      ## System Configuration Context

      **CRITICAL**: This Mac is configured almost entirely through Nix (nix-darwin + home-manager) managed in the dotfiles repository (`~/.dotfiles`).

      - **ALL system-level configuration** is managed via Nix configuration files
      - **ALL CLI tools and system utilities** are installed and configured through Nix
      - When investigating ANY system behavior, always check the dotfiles Nix configs FIRST
      - Never suggest manual changes to things managed by Nix (they will be overwritten on rebuild)
      - If the dotfiles repo is not the current working directory, reference `~/.dotfiles` for system configuration
      - Common locations:
        - System preferences -> `~/.dotfiles/modules/system.nix`
        - User programs -> `~/.dotfiles/home/programs/*.nix`
        - Homebrew packages -> `~/.dotfiles/modules/brew.nix`
        - Environment variables -> `~/.dotfiles/home/default.nix` or program-specific configs
        - AI tools config -> `~/.dotfiles/home/programs/ai/`

      ## Required Tasks

      **See "TOOL SELECTION MATRIX" and "SKILL LOADING REQUIREMENTS" above for complete rules.**

      Key reminders:
      - Use `jj` (not git), `fd` (not find), `rg` (not grep), `bd` (beads for tasks), `~/bin/ntfy` (notifications)
      - Load relevant skills before acting (see skill loading table above)
      - NEVER push to GitHub without explicit user consent each time

      ## Available Skills

      **See "SKILL LOADING REQUIREMENTS" above for when to load each skill.**

      Skills are inline reference knowledge. Load via internal skill loading mechanism.

      | Skill | Purpose | Trigger |
      |-------|---------|---------|
      | `nix` | Nix ecosystem, darwin, home-manager, flakes | <80% confidence on syntax |
      | `cli-tools` | fd/rg for file/content search | Before directory/script searches |
      | `jj` | Jujutsu version control workflow | Before ANY jj command |
      | `smart-ntfy` | Multi-channel notification routing | Before sending notifications |
      | `image-handling` | resize-image script, API constraints | Before resizing images |
      | `web-debug` | Chrome DevTools + Playwright MCP | Before browser debugging |
      | `shade` | Shade app IPC, nvim RPC debugging | Before debugging Shade |
      | `hs` | Hammerspoon config, reload, macOS APIs | Before editing HS config |
      | `nvim` | Neovim config, plugins, LSP patterns | Before editing nvim config |
      | `tmux` | tmux sessions, panes, windows, orchestration | Before tmux interaction |

      ## Available Agents

      **Spawn via Task tool for autonomous exploration and research.**

      Agents run as subprocesses with their own context. Use when task requires
      multi-step exploration or would benefit from parallel investigation.

      | Agent | Purpose | When to Use |
      |-------|---------|-------------|
      | `dots` | Navigate dotfiles repo structure | Finding where things are configured |
      | `nix` | Autonomous Nix exploration | Tracing options, debugging eval issues |
      | `hammerspoon` | Deep HS debugging and tracing | Memory leaks, watcher issues, macOS API problems |
      | `nvim` | Deep nvim debugging and tracing | LSP issues, plugin behavior, keybinding problems |

      **Note**: Skill `hs` and agent `hammerspoon` both cover Hammerspoon. Use the skill for
      quick reference, spawn the agent for deep investigation.

      ## Available Commands (Slash Commands)

      **Invoke with /command-name in chat.**

      | Command | Aliases | Purpose |
      |---------|---------|---------|
      | `/start` | `/go` | Start work session - sync remote, check bd ready |
      | `/finish` | `/end`, `/done` | End session - review changes, update beads, prep push |

      ## Question Format Convention (OpenCode Only)

      **NOTE**: This section applies only when running in OpenCode, not Claude Code.

      When you have multiple questions that require user input before proceeding, format them with numbered prefixes:

      ```
      QUESTION 1. First question here?
      QUESTION 2. Second question here?
      QUESTION 3. Third question here?
      ```

      This allows the user to respond with numbered answers like: 1. yes 2. no 3. maybe
    '';

    # =========================================================================
    # Settings
    # =========================================================================
    settings = {
      theme = "dark";
      autoUpdates = false;
      includeCoAuthoredBy = false;
      autoCompactEnabled = false;
      enableAllProjectMcpServers = true;
      feedbackSurveyState.lastShownTime = 1754089004345;
      outputStyle = "Explanatory";
      statusLine = {
        type = "command";
        command = "${config.home.homeDirectory}/bin/claude-statline";
        padding = 0;
      };
    };

    # =========================================================================
    # MCP Servers
    # =========================================================================
    mcpServers = allMcpServers;

    # =========================================================================
    # Skills - Inline reference knowledge
    # Invoked synchronously for guidance during conversation
    # =========================================================================
    skills = {
      # Nix ecosystem expert for dotfiles, darwin, home-manager, and project flakes
      nix = builtins.readFile ../../../docs/skills/nix.md;

      # Modern CLI tools (fd, rg) - critical for Nix store searches
      cli-tools = builtins.readFile ../../../docs/skills/cli-tools.md;

      # Jujutsu version control workflow and commands
      jj = builtins.readFile ../../../docs/skills/jj.md;

      # Smart notification system with multi-channel routing
      smart-ntfy = builtins.readFile ../../../docs/skills/smart-ntfy.md;

      # Image handling for Claude API constraints
      image-handling = builtins.readFile ../../../docs/skills/image-handling.md;

      # Web debugging with Chrome DevTools MCP
      web-debug = builtins.readFile ../../../docs/skills/web-debug.md;

      # Shade app - native Swift note capture panel
      shade = builtins.readFile ../../../docs/skills/shade.md;

      # Hammerspoon - macOS automation quick reference
      hs = builtins.readFile ../../../docs/skills/hs.md;

      # Neovim - config structure, plugins, LSP patterns
      nvim = builtins.readFile ../../../docs/skills/nvim.md;

      # tmux - terminal multiplexer configuration and orchestration
      tmux = builtins.readFile ../../../docs/skills/tmux.md;
    };

    # =========================================================================
    # Agents - Autonomous subprocesses for delegated tasks
    # Spawned via Task tool for exploration, research, and complex operations
    # =========================================================================
    agents = {
      # Dotfiles navigator - central guide for finding things in this repo
      dots = builtins.readFile ../../../docs/agents/dots.md;

      # Nix exploration agent for autonomous investigation of nix configs
      nix = builtins.readFile ../../../docs/agents/nix.md;

      # Hammerspoon expert for macOS automation and debugging
      hammerspoon = builtins.readFile ../../../docs/agents/hammerspoon-expert.md;

      # Neovim expert for deep debugging and tracing
      nvim = builtins.readFile ../../../docs/agents/nvim.md;
    };

    # =========================================================================
    # Commands - Custom slash commands
    # Invoked with /command-name in the chat
    # =========================================================================
    commands = {
      # Session management
      start = builtins.readFile ../../../docs/commands/start.md;
      go = builtins.readFile ../../../docs/commands/start.md; # alias

      finish = builtins.readFile ../../../docs/commands/finish.md;
      end = builtins.readFile ../../../docs/commands/finish.md; # alias
      done = builtins.readFile ../../../docs/commands/finish.md; # alias
    };
  };
}
