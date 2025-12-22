# mkProjectClaude - Generate project-specific AI agent configurations
# 
# This helper creates configuration files for both Claude Code and OpenCode,
# allowing project-specific MCP server configurations and settings.
#
# Generates:
#   - .claude/settings.local.json (Claude Code format)
#   - opencode.local.json (OpenCode format)
#
# Usage in project flake.nix:
#   inputs.dotfiles.url = "path:/Users/seth/.dotfiles";
#   
#   mkProjectAI = (import (inputs.dotfiles + "/lib/mkProjectClaude.nix")) inputs;
#   aiConfigs = mkProjectAI {inherit pkgs lib;} {
#     mcpServers = {
#       tidewave = {
#         type = "http";  # or "remote" for OpenCode
#         url = "http://localhost:4000/tidewave/mcp";
#       };
#     };
#     disableGlobalServers = [ "memory" "chrome-devtools" ];
#     agents = "both";  # "claude" | "opencode" | "both"
#   };
inputs: 
{ pkgs, lib, ... }: 
{
  # MCP servers to add/override for this project
  mcpServers ? {},
  
  # List of global MCP server names to disable (sets them to null for Claude, disabled for OpenCode)
  disableGlobalServers ? [],
  
  # Project-specific permissions (Claude Code only)
  permissions ? {},
  
  # Which agents to generate configs for: "claude" | "opencode" | "both"
  agents ? "both",
  
  # Additional Claude Code settings to merge
  extraClaudeSettings ? {},
  
  # Additional OpenCode settings to merge
  extraOpencodeSettings ? {},
}:
let
  # ===========================================================================
  # Claude Code Configuration
  # ===========================================================================
  
  # Disable global servers by setting them to null
  disabledServersForClaude = lib.genAttrs disableGlobalServers (_: null);
  
  # Merge project MCP servers with disabled globals
  claudeMcpServers = disabledServersForClaude // mcpServers;
  
  # Build the Claude Code config object
  claudeConfig = {
    mcpServers = claudeMcpServers;
  } // lib.optionalAttrs (permissions != {}) {
    permissions = permissions;
  } // extraClaudeSettings;
  
  claudeConfigJson = builtins.toJSON claudeConfig;
  claudeConfigFile = pkgs.writeText "claude-settings.local.json" claudeConfigJson;
  
  # ===========================================================================
  # OpenCode Configuration
  # ===========================================================================
  
  # Convert Claude MCP format to OpenCode format
  # Claude: { type = "http"; url = "..."; }
  # OpenCode: { type = "remote"; url = "..."; } (http servers become "remote")
  convertMcpServer = name: server: let
    # Map Claude's "http" type to OpenCode's "remote" type
    opencodeType = if server.type == "http" then "remote" else server.type;
  in {
    inherit (server) url;
    type = opencodeType;
    enabled = true;
  } // lib.optionalAttrs (server ? headers) {
    inherit (server) headers;
  } // lib.optionalAttrs (server ? environment) {
    inherit (server) environment;
  };
  
  # Convert all MCP servers
  opencodeMcpServers = lib.mapAttrs convertMcpServer mcpServers;
  
  # Build tools section to disable global servers
  opencodeDisabledTools = lib.genAttrs disableGlobalServers (_: false);
  
  # Build the OpenCode config object
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    mcp = opencodeMcpServers;
  } // lib.optionalAttrs (disableGlobalServers != []) {
    tools = opencodeDisabledTools;
  } // extraOpencodeSettings;
  
  opencodeConfigJson = builtins.toJSON opencodeConfig;
  opencodeConfigFile = pkgs.writeText "opencode.local.json" opencodeConfigJson;
  
  # ===========================================================================
  # Return appropriate configs based on 'agents' parameter
  # ===========================================================================
in
  if agents == "claude" then claudeConfigFile
  else if agents == "opencode" then opencodeConfigFile
  else if agents == "both" then {
    claude = claudeConfigFile;
    opencode = opencodeConfigFile;
  }
  else throw "Invalid 'agents' parameter. Must be 'claude', 'opencode', or 'both'"
