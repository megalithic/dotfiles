# AI Tools Configuration
# Manages Claude Code, OpenCode, and related AI tooling via Nix
#
# Structure:
#   - default.nix (this file): Shared config, packages, MCP servers
#   - claude-code.nix: Claude Code specific settings, skills, agents
#   - opencode.nix: OpenCode specific configuration
#
# Skills and agents are stored in docs/skills/*.md and docs/agents/*.md
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # ===========================================================================
  # Shared Configuration
  # ===========================================================================

  # Brave Browser Nightly path (used by both chrome-devtools and playwright MCP)
  braveBrowserPath = "${pkgs.brave-browser-nightly}/Applications/Brave Browser Nightly.app/Contents/MacOS/Brave Browser Nightly";

  # ===========================================================================
  # MCP Server Configuration (shared between Claude Code and OpenCode)
  # ===========================================================================

  # Use mcp-servers-nix evalModule to get the servers attrset directly
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

        # Playwright MCP for browser automation
        playwright = {
          enable = true;
          executable = braveBrowserPath;
        };
      };
    }).config.settings.servers;

  # Custom MCP servers not in mcp-servers-nix
  customMcpServers = {
    chrome-devtools = {
      command = "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp";
      args = [
        "--executablePath"
        braveBrowserPath
      ];
    };
  };

  # Combined MCP servers for Claude Code
  allMcpServers = mcpServersConfig // customMcpServers;

  # ===========================================================================
  # OpenCode MCP Server Transform
  # Claude: { command, args?, env? }
  # OpenCode: { type: "local", command: [cmd, ...args], enabled: true, environment? }
  # ===========================================================================
  toOpenCodeMcp =
    name: server:
    {
      type = "local";
      command =
        if server ? args && server.args != [ ] then
          [ server.command ] ++ server.args
        else
          [ server.command ];
      enabled = true;
    }
    // (lib.optionalAttrs (server ? env) { environment = server.env; });

  opencodeMcpServers = lib.mapAttrs toOpenCodeMcp allMcpServers;

in
{
  imports = [
    ./claude-code.nix
    ./opencode.nix
    ./ollama.nix
  ];

  # ===========================================================================
  # Pass shared config to submodules
  # ===========================================================================
  _module.args = {
    inherit allMcpServers opencodeMcpServers braveBrowserPath;
  };

  # ===========================================================================
  # AI Tool Packages
  # ===========================================================================
  # NOTE: claude-code is managed by programs.claude-code in claude-code.nix
  home.packages = [
    pkgs.llm-agents.opencode
    pkgs.llm-agents.claude-code-acp # DEPRECATED: hash override in overlays/default.nix
    pkgs.llm-agents.beads
  ];

  # ===========================================================================
  # Shared Files and Directories
  # ===========================================================================

  # Directory for MCP memory server storage
  home.file.".local/share/claude/.keep".text = "";

  # Force overwrite settings.json - it's 100% Nix-managed
  home.file.".claude/settings.json".force = true;

  # ===========================================================================
  # Activation Scripts
  # ===========================================================================

  # Symlink chrome-devtools-mcp binary to ~/.local/bin (for manual use)
  home.activation.linkAiBinaries = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    BIN_DIR="${config.home.homeDirectory}/.local/bin"
    mkdir -p "$BIN_DIR"

    # chrome-devtools-mcp
    rm -f "$BIN_DIR/chrome-devtools-mcp" 2>/dev/null || true
    ln -sf "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp" "$BIN_DIR/chrome-devtools-mcp"
  '';
}
