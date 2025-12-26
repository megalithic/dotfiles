# Uses the official home-manager programs.claude-code module for declarative config.
# MCP servers are passed via --mcp-config flag (wrapper handles this automatically).
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # ===========================================================================
  # resize-image - Resize images for Claude/LLM API constraints
  # ===========================================================================
  # Claude's image restrictions:
  #   - Max 5MB file size
  #   - Max 8000px on any dimension (width or height)
  #
  # Usage:
  #   resize-image <input> [output]     # Resize if needed
  #   resize-image --check <input>      # Check if image needs resizing
  #   resize-image --info <input>       # Show image dimensions and size
  resize-image = pkgs.writeShellApplication {
    name = "resize-image";
    runtimeInputs = with pkgs; [imagemagickBig coreutils bc];
    text = ''
      set -euo pipefail

      # Constants - Claude API limits
      MAX_SIZE_BYTES=5242880  # 5MB
      MAX_DIMENSION=8000      # 8000px max on any side
      DEFAULT_QUALITY=85      # JPEG quality for compression

      usage() {
        cat << 'EOF'
      Usage: resize-image [OPTIONS] <input> [output]

      Resize images to fit within Claude's API constraints:
        - Max file size: 5MB
        - Max dimension: 8000px (width or height)

      Options:
        --check       Check if image needs resizing (exit 0 = needs resize, 1 = OK)
        --info        Show image dimensions and file size
        --quality N   JPEG quality 1-100 (default: 85)
        --max-dim N   Max dimension in pixels (default: 8000)
        --max-size N  Max file size in bytes (default: 5242880)
        -h, --help    Show this help message

      Arguments:
        input         Input image file
        output        Output file (default: <input>-resized.<ext>)

      Examples:
        resize-image photo.png                    # Resize if needed
        resize-image photo.png small.png          # Resize to specific output
        resize-image --check photo.png            # Check if resize needed
        resize-image --info photo.png             # Show dimensions and size
        resize-image --quality 70 huge.jpg        # Use lower quality for more compression
      EOF
      }

      # Get image dimensions (WxH)
      get_dimensions() {
        magick identify -format "%wx%h" "$1" 2>/dev/null | head -1
      }

      # Get file size in bytes
      get_size() {
        stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null
      }

      # Check if image exceeds limits
      needs_resize() {
        local file="$1"
        local dims size width height

        dims=$(get_dimensions "$file")
        size=$(get_size "$file")
        width=''${dims%x*}
        height=''${dims#*x}

        # Check dimension limits
        if [[ "$width" -gt "$MAX_DIMENSION" ]] || [[ "$height" -gt "$MAX_DIMENSION" ]]; then
          return 0  # needs resize
        fi

        # Check file size
        if [[ "$size" -gt "$MAX_SIZE_BYTES" ]]; then
          return 0  # needs resize
        fi

        return 1  # OK
      }

      # Show image info
      show_info() {
        local file="$1"
        local dims size width height size_mb

        dims=$(get_dimensions "$file")
        size=$(get_size "$file")
        width=''${dims%x*}
        height=''${dims#*x}
        size_mb=$(echo "scale=2; $size / 1048576" | bc)

        echo "File: $file"
        echo "Dimensions: ''${width}x''${height}"
        echo "File size: ''${size_mb}MB ($size bytes)"

        # Check against limits
        local issues=()
        if [[ "$width" -gt "$MAX_DIMENSION" ]]; then
          issues+=("width exceeds $MAX_DIMENSION px")
        fi
        if [[ "$height" -gt "$MAX_DIMENSION" ]]; then
          issues+=("height exceeds $MAX_DIMENSION px")
        fi
        if [[ "$size" -gt "$MAX_SIZE_BYTES" ]]; then
          issues+=("file size exceeds 5MB")
        fi

        if [[ ''${#issues[@]} -gt 0 ]]; then
          echo "Status: NEEDS RESIZE"
          echo "Issues: ''${issues[*]}"
          return 0
        else
          echo "Status: OK (within Claude limits)"
          return 1
        fi
      }

      # Resize the image
      resize_image() {
        local input="$1"
        local output="$2"
        local quality="$3"

        local dims width height
        dims=$(get_dimensions "$input")
        width=''${dims%x*}
        height=''${dims#*x}

        # Calculate scale factor for dimensions
        local scale=100
        if [[ "$width" -gt "$MAX_DIMENSION" ]] || [[ "$height" -gt "$MAX_DIMENSION" ]]; then
          local scale_w scale_h
          scale_w=$(echo "scale=4; $MAX_DIMENSION * 100 / $width" | bc)
          scale_h=$(echo "scale=4; $MAX_DIMENSION * 100 / $height" | bc)
          # Use the smaller scale to ensure both dimensions fit
          if (( $(echo "$scale_w < $scale_h" | bc -l) )); then
            scale="$scale_w"
          else
            scale="$scale_h"
          fi
        fi

        # First pass: resize for dimensions
        local temp_file
        temp_file=$(mktemp --suffix=".png")
        trap 'rm -f "$temp_file"' EXIT

        if (( $(echo "$scale < 100" | bc -l) )); then
          echo "Resizing dimensions by ''${scale}%..."
          magick "$input" -resize "''${scale}%" "$temp_file"
        else
          cp "$input" "$temp_file"
        fi

        # Second pass: compress if still too large
        local current_size
        current_size=$(get_size "$temp_file")

        if [[ "$current_size" -gt "$MAX_SIZE_BYTES" ]]; then
          echo "Compressing (quality: $quality)..."
          # Use JPEG for better compression on photos, PNG for graphics
          local ext="''${output##*.}"
          ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

          if [[ "$ext" == "jpg" ]] || [[ "$ext" == "jpeg" ]]; then
            magick "$temp_file" -quality "$quality" "$output"
          else
            # For PNG, try reducing colors and compression
            magick "$temp_file" -quality "$quality" -strip "$output"
          fi

          # If still too large, progressively reduce quality
          current_size=$(get_size "$output")
          local try_quality=$quality
          while [[ "$current_size" -gt "$MAX_SIZE_BYTES" ]] && [[ "$try_quality" -gt 20 ]]; do
            try_quality=$((try_quality - 10))
            echo "Still too large, trying quality $try_quality..."
            if [[ "$ext" == "jpg" ]] || [[ "$ext" == "jpeg" ]]; then
              magick "$temp_file" -quality "$try_quality" "$output"
            else
              # Convert to JPEG if PNG won't compress enough
              local jpg_output="''${output%.*}.jpg"
              echo "Converting to JPEG for better compression..."
              magick "$temp_file" -quality "$try_quality" "$jpg_output"
              output="$jpg_output"
            fi
            current_size=$(get_size "$output")
          done
        else
          cp "$temp_file" "$output"
        fi

        # Final report
        local final_dims final_size final_mb
        final_dims=$(get_dimensions "$output")
        final_size=$(get_size "$output")
        final_mb=$(echo "scale=2; $final_size / 1048576" | bc)

        echo ""
        echo "Output: $output"
        echo "Dimensions: $final_dims"
        echo "File size: ''${final_mb}MB ($final_size bytes)"

        if [[ "$final_size" -le "$MAX_SIZE_BYTES" ]]; then
          echo "Status: OK (within Claude limits)"
        else
          echo "Warning: Could not compress below 5MB limit"
          return 1
        fi
      }

      # Parse arguments
      MODE="resize"
      QUALITY="$DEFAULT_QUALITY"
      INPUT=""
      OUTPUT=""

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --check)
            MODE="check"
            shift
            ;;
          --info)
            MODE="info"
            shift
            ;;
          --quality)
            QUALITY="$2"
            shift 2
            ;;
          --max-dim)
            MAX_DIMENSION="$2"
            shift 2
            ;;
          --max-size)
            MAX_SIZE_BYTES="$2"
            shift 2
            ;;
          -h|--help)
            usage
            exit 0
            ;;
          -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
          *)
            if [[ -z "$INPUT" ]]; then
              INPUT="$1"
            elif [[ -z "$OUTPUT" ]]; then
              OUTPUT="$1"
            else
              echo "Too many arguments" >&2
              usage >&2
              exit 1
            fi
            shift
            ;;
        esac
      done

      # Validate input
      if [[ -z "$INPUT" ]]; then
        echo "Error: No input file specified" >&2
        usage >&2
        exit 1
      fi

      if [[ ! -f "$INPUT" ]]; then
        echo "Error: File not found: $INPUT" >&2
        exit 1
      fi

      # Generate default output filename
      if [[ -z "$OUTPUT" ]]; then
        ext="''${INPUT##*.}"
        base="''${INPUT%.*}"
        OUTPUT="''${base}-resized.''${ext}"
      fi

      # Execute based on mode
      case "$MODE" in
        check)
          if needs_resize "$INPUT"; then
            echo "needs-resize"
            exit 0
          else
            echo "ok"
            exit 1
          fi
          ;;
        info)
          show_info "$INPUT"
          ;;
        resize)
          if ! needs_resize "$INPUT"; then
            echo "Image already within limits, no resize needed"
            echo "Use --info to see dimensions and size"
            exit 0
          fi
          resize_image "$INPUT" "$OUTPUT" "$QUALITY"
          ;;
      esac
    '';
  };
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
    pkgs.llm-agents.claude-code-acp
    pkgs.llm-agents.beads
    resize-image # Resize images for Claude/LLM API constraints (5MB, 8000px)
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
  # Uses absolute Nix store path for reliability
  xdg.configFile."opencode/tool/resize-image.ts".text = ''
    import { tool } from "@opencode-ai/plugin"

    const RESIZE_IMAGE = "${resize-image}/bin/resize-image"

    export default tool({
      description: "Resize images to fit within Claude's API constraints (5MB max file size, 8000px max dimension). Use this when an image is too large to process.",
      args: {
        path: tool.schema.string().describe("Absolute path to the image file"),
        output: tool.schema.string().optional().describe("Output path (default: <input>-resized.<ext>)"),
        quality: tool.schema.number().optional().describe("JPEG quality 1-100 (default: 85)"),
      },
      async execute(args) {
        const cmd = [RESIZE_IMAGE]
        if (args.quality) cmd.push("--quality", String(args.quality))
        cmd.push(args.path)
        if (args.output) cmd.push(args.output)
        const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" })
        const stdout = await new Response(proc.stdout).text()
        const stderr = await new Response(proc.stderr).text()
        await proc.exited
        return (stdout + stderr).trim()
      },
    })

    export const check = tool({
      description: "Check if an image needs resizing for Claude's API (5MB max, 8000px max dimension)",
      args: {
        path: tool.schema.string().describe("Absolute path to the image file"),
      },
      async execute(args) {
        const proc = Bun.spawn([RESIZE_IMAGE, "--check", args.path], { stdout: "pipe", stderr: "pipe" })
        const stdout = await new Response(proc.stdout).text()
        await proc.exited
        return stdout.trim()
      },
    })

    export const info = tool({
      description: "Show image dimensions and file size, and whether it exceeds Claude's limits",
      args: {
        path: tool.schema.string().describe("Absolute path to the image file"),
      },
      async execute(args) {
        const proc = Bun.spawn([RESIZE_IMAGE, "--info", args.path], { stdout: "pipe", stderr: "pipe" })
        const stdout = await new Response(proc.stdout).text()
        await proc.exited
        return stdout.trim()
      },
    })
  '';
}
