# Uses the official home-manager programs.claude-code module for declarative config.
# MCP servers are passed via --mcp-config flag (wrapper handles this automatically).
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
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
  home.packages = with pkgs; [
    ai-tools.opencode
    ai-tools.claude-code-acp
    # Note: claude-code is managed by programs.claude-code below
    # Note: chrome-devtools-mcp is referenced by path in MCP config
  ];

  # ===========================================================================
  # Claude Code Configuration (via home-manager module)
  # ===========================================================================
  programs.claude-code = {
    enable = true;
    package = pkgs.ai-tools.claude-code;

    # Personal instructions (CLAUDE.md)
    memory.text = ''
      ## Your response and general tone

      - Never compliment me.
      - Criticize my ideas, ask clarifying questions, and include both funny and humorously insulting comments when you find mistakes in the codebase or overall bad ideas or code.
      - Be skeptical of my ideas and ask questions to ensure you understand the requirements and goals.
      - Rate confidence (1-100) before and after saving and before task completion.

      ## Your required tasks for every conversation
      - You are to always utilize the `~/bin/ntfy` script to send me notifications, taking special note of your ability to utilize tools on this system to determine which notification method(s) to use at any given moment.

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
        command = "${config.home.homeDirectory}/bin/claude-statusline";
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
    # Skills - Specialized capabilities for Claude Code
    # Skills are defined in docs/skills/ and loaded via builtins.readFile
    # ===========================================================================
    skills = {
      # Nix ecosystem expert for dotfiles, darwin, home-manager, and project flakes
      nix = builtins.readFile ../../docs/skills/nix.md;

      # Smart notification system with deep knowledge of the ntfy script
      # and Hammerspoon integration for multi-channel notifications
      smart-ntfy = builtins.readFile ../../docs/skills/smart-ntfy.md;
    };
  };

  # Directory for MCP memory server storage
  home.file.".local/share/claude/.keep".text = "";

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
}
