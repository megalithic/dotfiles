# OpenCode Configuration
# Settings and MCP servers for OpenCode AI tool
{
  config,
  pkgs,
  lib,
  opencodeMcpServers,
  ...
}:
{
  # ===========================================================================
  # OpenCode Configuration File
  # ===========================================================================
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";

    # Instructions file - OpenCode reads CLAUDE.md from .claude/ directory
    # which is symlinked from Nix store (managed by programs.claude-code.memory.text)
    instructions = [ "CLAUDE.md" ];

    # Appearance
    theme = "everforest";

    # Model selection
    model = "anthropic/claude-opus-4.5";

    # Behavior
    autoshare = false;
    autoupdate = true;

    # Keybindings
    keybinds = {
      leader = "ctrl+,";
      session_new = "ctrl+n";
      session_list = "ctrl+g";
      messages_half_page_up = "ctrl+b";
      messages_half_page_down = "ctrl+f";
    };

    # LSP configurations for code intelligence
    lsp = {
      php = {
        command = [
          "intelephense"
          "--stdio"
        ];
        extensions = [ ".php" ];
      };
      python = {
        command = [
          "basedpyright"
          "--stdio"
        ];
        extensions = [ ".py" ];
      };
    };

    # MCP servers - transformed from Claude Code format
    mcp = opencodeMcpServers;
  };

  # ===========================================================================
  # OpenCode Custom Tools (disabled - kept for reference)
  # ===========================================================================
  # Custom tool for resizing images - wraps resize-image CLI
  # Uses absolute path to externalized script in dotfiles bin/
  #
  # xdg.configFile."opencode/tool/resize-image.ts".text = ''
  #   import { tool } from "@opencode-ai/plugin"
  #
  #   const RESIZE_IMAGE = "${config.home.homeDirectory}/.dotfiles/bin/resize-image"
  #
  #   export default tool({
  #     description: "Resize images to fit within Claude's API constraints (5MB max file size, 8000px max dimension).",
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
  # '';
}
