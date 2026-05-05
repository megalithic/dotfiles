# 1Password integration
#
# Single source of truth for all 1Password-related configuration:
#   - Package install (GUI + CLI, migrated from brew cask to nixpkgs 2026-05-05)
#   - SSH agent socket (`IdentityAgent` in ~/.ssh/config)
#   - Allow-listed keys via 1Password's `agent.toml`
#   - SSH-based commit signing (git + jj) using `op-ssh-sign`
#   - `SSH_AUTH_SOCK` exposed to user shells
#   - Fish `opl` function + cached `OP_SESSION_*` restoration
#
# CAVEAT (2026-05-05): 1Password 8 enforces `/Applications/1Password.app`
# (anti-tamper check — logs `detected repeated launch from a bad location`).
# Our custom `mkAppActivation` copies it to `~/Applications/1Password.app`
# which should satisfy the check (or at least avoid the "bad location" 
# subdir).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentSocket = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock";
  opSshSignPath = "${config.home.homeDirectory}/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  sessionCachePath = "${config.home.homeDirectory}/.local/cache/op/sessions";
in
{
  options.mega.onepassword = {
    agentSocket = lib.mkOption {
      type = lib.types.str;
      default = agentSocket;
      readOnly = true;
      description = "1Password SSH agent UNIX socket path.";
    };
    opSshSign = lib.mkOption {
      type = lib.types.str;
      default = opSshSignPath;
      readOnly = true;
      description = "Path to op-ssh-sign for SSH-based commit signing (git, jj).";
    };
    sessionCache = lib.mkOption {
      type = lib.types.str;
      default = sessionCachePath;
      readOnly = true;
      description = "File holding cached OP_SESSION_* exports (managed by `opl`).";
    };
  };

  config = {
    # 1Password packages (migrated from brew cask 2026-05-05)
    # appLocation = "copy" because 1Password 8 anti-tamper check rejects symlinks
    home.packages = [
      (pkgs._1password-gui.overrideAttrs (old: {
        passthru = (old.passthru or {}) // { appLocation = "copy"; };
      }))
      pkgs._1password-cli
    ];

    # Allow-listed SSH keys exposed by the 1Password agent
    xdg.configFile."1Password/ssh/agent.toml".text = ''
      [[ssh-keys]]
      vault = "Shared"
      item = "megaenv_ssh_key"
    '';

    # Route SSH through 1Password's agent (Touch ID auth)
    programs.ssh.matchBlocks."* \"test -z $SSH_TTY\"".identityAgent = agentSocket;

    # Expose to shells so non-`programs.ssh` consumers see the agent
    home.sessionVariables.SSH_AUTH_SOCK = agentSocket;

    # SSH-based commit signing, both VCSes
    programs.git.settings.gpg.ssh.program = opSshSignPath;
    programs.jujutsu.settings.signing.backends.ssh.program = opSshSignPath;

    # Restore cached OP_SESSION_* on every fish startup (populated by `opl`)
    programs.fish.shellInit = lib.mkAfter ''
      if test -f ${sessionCachePath}
        while read -l line
          set -l parts (string split -m1 = $line)
          if test (count $parts) -eq 2
            set -gx $parts[1] $parts[2]
          end
        end < ${sessionCachePath}
      end
    '';

    # `opl` — fish helper to sign in to all accounts and cache OP_SESSION_*
    programs.fish.functions.opl = {
      description = "1Password CLI session manager (login, restore, status)";
      body = ''
        set -l cache_dir ~/.local/cache/op
        set -l cache_file $cache_dir/sessions

        # Subcommands
        switch "$argv[1]"
          case status
            # Show current session state
            set -l vars (env | string match 'OP_SESSION_*')
            if test (count $vars) -eq 0
              echo "No active OP_SESSION_* variables"
            else
              for v in $vars
                set -l name (string split -m1 = $v)[1]
                echo "  $name = (set)"
              end
            end
            if test -f $cache_file
              echo "Cache: $cache_file (age: "(math (date +%s) - (stat -f%m $cache_file))"s)"
            else
              echo "Cache: none"
            end
            return 0

          case restore
            # Restore cached sessions into current shell
            if not test -f $cache_file
              echo "No cached sessions. Run: opl" >&2
              return 1
            end
            while read -l line
              set -l parts (string split -m1 = $line)
              if test (count $parts) -eq 2
                set -gx $parts[1] $parts[2]
              end
            end < $cache_file
            echo "Restored OP_SESSION_* from cache"
            return 0

          case help -h --help
            echo "Usage: opl [command]"
            echo ""
            echo "Commands:"
            echo "  (none)    Sign in to 1Password accounts and cache sessions"
            echo "  restore   Restore cached sessions into current shell"
            echo "  status    Show current session state"
            echo "  help      Show this help"
            echo ""
            echo "Sessions are cached to $cache_dir/sessions"
            echo "New shells auto-restore cached sessions on startup."
            return 0

          case ""
            # Default: sign in and cache

          case "*"
            echo "Unknown command: $argv[1]. Run: opl help" >&2
            return 1
        end

        # Sign in to accounts
        eval (op signin --account my)
        or begin
          echo "Failed to sign in to 'my' account" >&2
          return 1
        end

        eval (op signin --account evirts)
        or echo "Warning: failed to sign in to 'evirts' account" >&2

        # Cache session tokens (name=value pairs)
        mkdir -p $cache_dir
        env | string match 'OP_SESSION_*' > $cache_file
        echo "Sessions cached to $cache_file"
      '';
    };
  };
}
