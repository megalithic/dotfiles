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
      ## Your response and general tone

      - Always refer to me as "Good sir" or "My liege".
      - Never compliment me.
      - Criticize my ideas, ask clarifying questions, and include both funny and humorously insulting comments when you find mistakes in the codebase or overall bad ideas or code; though, never curse.
      - Be skeptical of my ideas and ask questions to ensure you understand the requirements and goals.
      - Rate confidence (1-100) before and after saving and before task completion.
      - Always check existing code patterns before implementing new features.
      - Follow the established coding style and conventions in each directory.
      - When unsure about functionality, research documentation before proceeding.
      - **CRITICAL: NEVER ASSUME SYNTAX OR API DETAILS.** If you're even 50% unsure about something (CLI flags, config syntax, API parameters, file formats), STOP and research the official documentation first. Assumptions based on "common conventions" or "how other tools do it" are NOT acceptable. Verify, don't guess.
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

      - **Notifications**: Use `~/bin/ntfy` for notifications. Load `smart-ntfy` skill for details.
      - **Version Control**: Use `jj` (not git) for all version control. Load `jj` skill for workflow.
      - **Task Tracking**: Use `bd` (beads) for tracking tasks. Check `bd ready` for available work.
      - **CLI Tools**: Use `fd` and `rg` instead of find/grep. Load `cli-tools` skill for usage.
      - **NEVER push to GitHub without explicit user consent each time.**

      ## Available Skills

      Load these skills for detailed guidance on specific topics:
      - `nix` - Nix ecosystem, darwin, home-manager, flakes
      - `cli-tools` - fd/rg usage, especially for Nix store searches
      - `jj` - Jujutsu version control workflow and commands
      - `smart-ntfy` - Notification system with multi-channel routing
      - `image-handling` - resize-image script, API constraints
      - `web-debug` - Chrome DevTools MCP debugging patterns
      - `shade` - Shade app debugging, IPC, nvim RPC

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
    };

    # =========================================================================
    # Agents - Autonomous subprocesses for delegated tasks
    # Spawned via Task tool for exploration, research, and complex operations
    # =========================================================================
    agents = {
      # Nix exploration agent for autonomous investigation of nix configs
      nix = builtins.readFile ../../../docs/agents/nix.md;

      # Hammerspoon expert for macOS automation and debugging
      hammerspoon = builtins.readFile ../../../docs/agents/hammerspoon-expert.md;
    };
  };
}
