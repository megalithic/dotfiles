# Uses the official home-manager programs.claude-code module for declarative config.
# MCP servers are passed via --mcp-config flag (wrapper handles this automatically).
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Path to externalized resize-image script (lives in dotfiles bin/)
  # Dependencies (imagemagick, bc, coreutils) are available via Nix profile
  resize-image-bin = "${config.home.homeDirectory}/.dotfiles/bin/resize-image";

  # Use mcp-servers-nix evalModule to get the servers attrset directly
  # This gives us the raw config structure we can pass to programs.claude-code.mcpServers
  mcpServersConfig =
    (inputs.mcp-servers-nix.lib.evalModule pkgs {
      programs = {
        memory = {
          enable = true;
          env.MEMORY_FILE_PATH = "${config.home.homeDirectory}/.local/share/claude/memory.jsonl";
        };
        context7.enable = true;
        terraform.enable = false;
        nixos.enable = false;
        codex.enable = false;
        serena = {
          enable = false;
          args = [
            "--context"
            "ide-assistant"
            "--enable-web-dashboard"
            "False"
          ];
        };

        # Disabled servers (kept for reference)
        # filesystem.enable = false;
        # fetch.enable = false;
        # git.enable = false;
        # time.enable = false;
        # playwright.enable = false;
      };
    }).config.settings.servers;

  # Custom MCP servers not in mcp-servers-nix
  customMcpServers = {
    chrome-devtools = {
      command = "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp";
      args = [
        "--executablePath"
        "${pkgs.brave-browser-nightly}/Applications/Brave Browser Nightly.app/Contents/MacOS/Brave Browser Nightly"
      ];
    };
  };
in {
  # ===========================================================================
  # AI Tool Packages (non-Claude)
  # ===========================================================================
  # NOTE: claude-code is managed by programs.claude-code below
  # NOTE: chrome-devtools-mcp is referenced by path in MCP config
  home.packages = [
    pkgs.llm-agents.opencode
    pkgs.llm-agents.claude-code-acp # hash override in overlays/default.nix
    pkgs.llm-agents.beads
    # resize-image is now externalized to ~/.dotfiles/bin/resize-image
  ];

  # ===========================================================================
  # Claude Code Configuration (via home-manager module)
  # ===========================================================================
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;

    # Personal instructions (CLAUDE.md)
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
      - **CRITICAL: NEVER ASSUME SYNTAX OR API DETAILS.** If you're even 50% unsure about something (CLI flags, config syntax, API parameters, file formats), STOP and research the official documentation first. Assumptions based on "common conventions" or "how other tools do it" are NOT acceptable. This has caused real bugs (e.g., assuming `px` suffix works in Kitty config when it doesn't). Verify, don't guess.
      - Never modify files outside of the current working project directory without my explicit consent.

      ## System Configuration Context

      **CRITICAL**: This Mac is configured almost entirely through Nix (nix-darwin + home-manager) managed in the dotfiles repository (`~/.dotfiles`).

      - **ALL system-level configuration** is managed via Nix configuration files
      - **ALL CLI tools and system utilities** are installed and configured through Nix
      - When investigating ANY system behavior, always check the dotfiles Nix configs FIRST
      - Never suggest manual changes to things managed by Nix (they will be overwritten on rebuild)
      - If the dotfiles repo is not the current working directory, reference `~/.dotfiles` for system configuration
      - Common locations:
        - System preferences → `~/.dotfiles/modules/system.nix`
        - User programs → `~/.dotfiles/home/programs/*.nix`
        - Homebrew packages → `~/.dotfiles/modules/brew.nix`
        - Environment variables → `~/.dotfiles/home/default.nix` or program-specific configs
        - Claude Code config → `~/.dotfiles/home/programs/ai.nix`

      ## Your required tasks for every conversation

      - You are to always utilize the `~/bin/ntfy` script to send me notifications, taking special note of your ability to utilize tools on this system (like hammerspoon and the notification-related modules, and more) to determine which notification method(s) to use at any given moment.
      - You are to always attempt to use `jj` to create a new "commit" or "bookmark" that you'll later describe, for every logical unit of work; if `jj` is unavailable in the given repo or directory, then explicitly request my permission to use `git` instead.
      - **NEVER push to GitHub (or any remote) without explicit user consent each time.** Always ask before running `jj git push`, `git push`, or equivalent commands. Commits are cheap; pushes are permanent.

      ### Beads used for tracking tasks (CRITICAL)

      **CRITICAL**: You must use beads (`bd`) for tracking tasks and units of work, as well as informing yourself and other AI agents of context and progress:

      - You are to check prior bead epics and tasks, keeping up with what needs to be completed, and ensuring `jj` bookmarks match up with bead tasks for consistency and end-user tracking as well.
      - You will provide end of task updates and overviews of bead epics and tasks for that epic.

      ### Jujutsu (jj) Command Transparency (CRITICAL)

      **CRITICAL**: When using `jj` in any repository, you MUST provide full transparency about every command:

      1. **Inline explanations** - When running any jj command, explain:
         - What the command does
         - Why you're running it at this point
         - What the expected outcome is

      2. **End-of-session summary** - Before ending a session where jj was used, provide a summary block:
         ```
         ## jj Commands Used This Session
         | Command | Purpose |
         |---------|---------|
         | `jj new -m "..."` | Started new unit of work |
         | `jj git fetch` | Pulled latest from remote |
         | ... | ... |
         ```

      This transparency helps the user:
      - Learn jj workflows through observation
      - Understand the version control state at any point
      - Catch mistakes before they become problems
      - Build confidence in the AI's version control decisions

      ## Notification System (ntfy)

      Quick reference for `~/bin/ntfy`:

      ```bash
      ntfy send -t "Title" -m "Message"                    # Basic
      ntfy send -t "Error" -m "Build failed" -u critical   # Critical (sends to phone)
      ntfy send -t "Question" -m "Continue?" -u high -q    # Question (retries until answered)
      ntfy send -t "Done" -m "Task complete" -p            # Send to phone
      ntfy answer -t "Question" -m "Continue?"             # Mark question answered
      ```

      Options: `-t/--title`, `-m/--message`, `-u/--urgency` (normal|high|critical), `-p/--phone`, `-P/--pushover`, `-q/--question`

      ## Image Handling (resize-image)

      **CRITICAL**: All images must fit within Anthropic's API constraints:
        - Max file size: **5MB**
        - Max dimension: **8000px** (width or height)

      ### MCP Screenshots (Chrome DevTools & Playwright)

      **CRITICAL**: When using `chrome-devtools` or `playwright` MCP servers to take screenshots:
        - NEVER take full-page screenshots of long pages (they will exceed limits)
        - Prefer viewport-only screenshots over `fullPage: true`
        - If you must capture a full page, save to file and resize before reading
        - For element screenshots, prefer smaller/focused elements

      When saving screenshots to disk via MCP tools, always run `resize-image --check` on the result before attempting to read or process it.

      ### General Image Workflow

      Always use the `resize-image` script before working with any image:

      ```bash
      resize-image --info <image>           # Check dimensions and size
      resize-image --check <image>          # Quick check: "needs-resize" or "ok"
      resize-image <image>                  # Resize if needed (creates <name>-resized.<ext>)
      resize-image <image> <output>         # Resize to specific output path
      resize-image --quality 70 <image>     # Lower quality for more compression
      ```

      **Workflow**:
      1. When user provides an image path, first run `resize-image --check <path>`
      2. If it outputs "needs-resize", run `resize-image <path>` and use the resized version
      3. If it outputs "ok", proceed with the original image

      This prevents API errors from oversized images and ensures smooth image processing.
    '';

    # Settings (written to ~/.claude/settings.json)
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

    # env = {
    #   BASH_DEFAULT_TIMEOUT_MS = "300000";
    #   BASH_MAX_TIMEOUT_MS = "1200000";
    #   CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
    #   MAX_MCP_OUTPUT_TOKENS = "50000";
    #   MCP_TOOL_TIMEOUT = "120000";
    #   CLAUDE_CODE_MAX_OUTPUT_TOKENS = "32000";
    #   CLAUDE_CODE_AUTO_CONNECT_IDE = "0";
    #   CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    #   CLAUDE_CODE_ENABLE_TELEMETRY = "0";
    #   CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = "1";
    #   CLAUDE_CODE_IDE_SKIP_VALID_CHECK = "1";
    #   DISABLE_AUTOUPDATER = "1";
    #   DISABLE_ERROR_REPORTING = "1";
    #   DISABLE_INTERLEAVED_THINKING = "1";
    #   DISABLE_MICROCOMPACT = "1";
    #   DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
    #   DISABLE_TELEMETRY = "1";
    # };

    # hooks = {
    #   Stop = [
    #     {
    #       hooks = [
    #         {
    #           type = "command";
    #           command = "terminal-notifier -message '🛑 claude-code halted' -title 'Claude Code' -sound Blow";
    #         }
    #       ];
    #     }
    #   ];
    # };

    # MCP servers (passed via --mcp-config flag)
    mcpServers = mcpServersConfig // customMcpServers;

    # ===========================================================================
    # Skills - Inline reference knowledge for Claude Code
    # Invoked synchronously for guidance during conversation
    # ===========================================================================
    skills = {
      # Nix ecosystem expert for dotfiles, darwin, home-manager, and project flakes
      nix = builtins.readFile ../../docs/skills/nix.md;
      # Smart notification system with deep knowledge of the ntfy script
      # and Hammerspoon integration for multi-channel notifications
      smart-ntfy = builtins.readFile ../../docs/skills/smart-ntfy.md;
      # Web debugging with Chrome DevTools MCP - intelligent validation,
      # app-specific context discovery, and performance optimization
      web-debug = builtins.readFile ../../docs/skills/web-debug.md;
    };

    # ===========================================================================
    # Agents - Autonomous subprocesses for delegated tasks
    # Spawned via Task tool for exploration, research, and complex operations
    # ===========================================================================
    agents = {
      # Nix exploration agent for autonomous investigation of nix configs
      # Use for: tracing options, finding patterns, debugging evaluation
      nix = builtins.readFile ../../docs/agents/nix.md;
    };
  };

  # Directory for MCP memory server storage
  home.file.".local/share/claude/.keep".text = "";

  # Force overwrite settings.json - it's 100% Nix-managed, no backup needed
  home.file.".claude/settings.json".force = true;

  # Symlink chrome-devtools-mcp binary to ~/.local/bin (for manual use)
  home.activation.linkAiBinaries = lib.hm.dag.entryAfter ["writeBoundary"] ''
    BIN_DIR="${config.home.homeDirectory}/.local/bin"
    mkdir -p "$BIN_DIR"

    # chrome-devtools-mcp
    rm -f "$BIN_DIR/chrome-devtools-mcp" 2>/dev/null || true
    ln -sf "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp" "$BIN_DIR/chrome-devtools-mcp"
  '';

  # ===========================================================================
  # OpenCode Configuration
  # ===========================================================================
  xdg.configFile."opencode/opencode.json".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "instructions": [
        "CLAUDE.md"
      ],
      "theme": "everforest",
      "model": "anthropic/claude-opus-4.5",
      "autoshare": false,
      "autoupdate": true,
      "keybinds": {
        "leader": "ctrl+,",
        "session_new": "ctrl+n",
        "session_list": "ctrl+g",
        "messages_half_page_up": "ctrl+b",
        "messages_half_page_down": "ctrl+f"
      },
      "lsp": {
        "php": {
          "command": [
            "intelephense",
            "--stdio"
          ],
          "extensions": [
            ".php"
          ]
        },
        "python": {
          "command": [
            "basedpyright",
            "--stdio"
          ],
          "extensions": [
            ".py"
          ]
        }
      }
    }
  '';

  # OpenCode custom tool for resizing images (wraps resize-image CLI)
  # Uses absolute path to externalized script in dotfiles bin/
  # xdg.configFile."opencode/tool/resize-image.ts".text = ''
  #   import { tool } from "@opencode-ai/plugin"
  #
  #   const RESIZE_IMAGE = "${resize-image-bin}"
  #
  #   export default tool({
  #     description: "Resize images to fit within Claude's API constraints (5MB max file size, 8000px max dimension). Use this when an image is too large to process.",
  #     args: {
  #       path: tool.schema.string().describe("Absolute path to the image file"),
  #       output: tool.schema.string().optional().describe("Output path (default: <input>-resized.<ext>)"),
  #       quality: tool.schema.number().optional().describe("JPEG quality 1-100 (default: 85)"),
  #     },
  #     async execute(args) {
  #       const cmd = [RESIZE_IMAGE]
  #       if (args.quality) cmd.push("--quality", String(args.quality))
  #       cmd.push(args.path)
  #       if (args.output) cmd.push(args.output)
  #       const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" })
  #       const stdout = await new Response(proc.stdout).text()
  #       const stderr = await new Response(proc.stderr).text()
  #       await proc.exited
  #       return (stdout + stderr).trim()
  #     },
  #   })
  #
  #   export const check = tool({
  #     description: "Check if an image needs resizing for Claude's API (5MB max, 8000px max dimension)",
  #     args: {
  #       path: tool.schema.string().describe("Absolute path to the image file"),
  #     },
  #     async execute(args) {
  #       const proc = Bun.spawn([RESIZE_IMAGE, "--check", args.path], { stdout: "pipe", stderr: "pipe" })
  #       const stdout = await new Response(proc.stdout).text()
  #       await proc.exited
  #       return stdout.trim()
  #     },
  #   })
  #
  #   export const info = tool({
  #     description: "Show image dimensions and file size, and whether it exceeds Claude's limits",
  #     args: {
  #       path: tool.schema.string().describe("Absolute path to the image file"),
  #     },
  #     async execute(args) {
  #       const proc = Bun.spawn([RESIZE_IMAGE, "--info", args.path], { stdout: "pipe", stderr: "pipe" })
  #       const stdout = await new Response(proc.stdout).text()
  #       await proc.exited
  #       return stdout.trim()
  #     },
  #   })
  # '';
}
