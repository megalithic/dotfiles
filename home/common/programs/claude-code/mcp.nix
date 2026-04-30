# MCP Server Configuration
# Shared between Claude Code (./default.nix) and OpenCode (../opencode/default.nix)
#
# Exposes via _module.args:
#   - allMcpServers: { name = { command, args?, env? }; ... }    (Claude Code format)
#   - opencodeMcpServers: { name = { type, command [...], ... }; ... }  (OpenCode format)
#   - braveBrowserPath: path to Brave Browser Nightly executable
#
# Adding a new MCP server:
#   - From mcp-servers-nix: enable in `mcpServersConfig.programs.<name>.enable = true`
#   - Custom (not in mcp-servers-nix): add to `customMcpServers` attrset below
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Brave Browser Nightly path (used by chrome-devtools and playwright MCP)
  braveBrowserPath = "${pkgs.brave-browser-nightly}/Applications/Brave Browser Nightly.app/Contents/MacOS/Brave Browser Nightly";

  # Use mcp-servers-nix evalModule to get the servers attrset directly
  mcpServersConfig =
    (inputs.mcp-servers-nix.lib.evalModule pkgs {
      programs = {
        memory = {
          enable = true;
          env.MEMORY_FILE_PATH = "${config.home.homeDirectory}/.local/share/claude/memory.jsonl";
        };
        context7.enable = false;
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
          enable = false;
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
  toOpenCodeMcp = name: server:
    {
      type = "local";
      command =
        if server ? args && server.args != []
        then [server.command] ++ server.args
        else [server.command];
      enabled = true;
    }
    // (lib.optionalAttrs (server ? env) {environment = server.env;});

  opencodeMcpServers = lib.mapAttrs toOpenCodeMcp allMcpServers;
in {
  # Expose to Claude Code and OpenCode modules
  _module.args = {
    inherit allMcpServers opencodeMcpServers braveBrowserPath;
  };

  # Memory MCP storage directory
  home.file.".local/share/claude/.keep".text = "";

  # Symlink chrome-devtools-mcp binary to ~/.local/bin (for manual use)
  home.activation.linkAiBinaries = lib.hm.dag.entryAfter ["writeBoundary"] ''
    BIN_DIR="${config.home.homeDirectory}/.local/bin"
    mkdir -p "$BIN_DIR"

    # chrome-devtools-mcp
    rm -f "$BIN_DIR/chrome-devtools-mcp" 2>/dev/null || true
    ln -sf "${pkgs.chrome-devtools-mcp}/bin/chrome-devtools-mcp" "$BIN_DIR/chrome-devtools-mcp"
  '';
}
