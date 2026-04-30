# Email accounts and shared mail-related utilities
#
# Account configuration (accounts.email.*) used by all email programs:
# - mbsync (programs/mbsync) - syncs IMAP to maildir
# - msmtp (programs/msmtp) - sends mail via SMTP
# - notmuch (programs/notmuch) - indexes and tags mail
# - aerc (programs/aerc) - TUI mail client
# - mailmate (programs/mailmate) - GUI mail client
#
# Shared utilities:
# - mailcap for content type handling
# - sync-mail / mail-search CLI scripts
# - email-related packages (mblaze, pandoc, etc.)
#
# REFS:
# - aerc/general mail: https://bence.ferdinandy.com/2023/07/20/email-in-the-terminal-a-complete-guide-to-the-unix-way-of-email
# - afew: https://github.com/heph2/infra/blob/main/hosts/freya/home.nix#L137-L172
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  ca-bundle_path = "${pkgs.cacert}/etc/ssl/certs/";
  ca-bundle_crt = "${ca-bundle_path}/ca-bundle.crt";
in {
  # Expose CA bundle for downstream email programs (msmtp, mbsync)
  _module.args = {
    inherit ca-bundle_path ca-bundle_crt;
  };

  home.packages = with pkgs; [
    maildir-rank-addr # Address book from maildir
    mblaze # Unix utilities for email
    pandoc
    w3m
  ];

  accounts.email = {
    certificatesFile = ca-bundle_crt;
    maildirBasePath = "${config.home.homeDirectory}/.mail";

    accounts = {
      fastmail = {
        primary = true;

        realName = "Seth Messer";
        address = "seth@megalithic.io";
        userName = "sethmesser@fastmail.com";
        passwordCommand = "op read op://Shared/Fastmail/apps/tui";
        flavor = "fastmail.com";
        aliases = [
          "seth@megalithic.io"
          "noreply@megalithic.io"
        ];
        signature = {
          text = ''
            Regards,
            Seth Messer
            seth@megalithic.io
          '';
          showSignature = "append";
        };
        aerc.enable = false;
        notmuch.enable = true;
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          remove = "both";
          extraConfig.channel = {
            CopyArrivalDate = "yes";
          };
        };
        # msmtp configuration for sending
        msmtp = {
          enable = true;
          extraConfig = {
            # Enable TLS
            tls_starttls = "on";
            # Log file for debugging
            logfile = "~/.cache/msmtp/msmtp.log";
          };
        };
        # Real-time IMAP notifications
        imapnotify = {
          enable = true;
          boxes = ["INBOX"];
          onNotify = "${pkgs.isync}/bin/mbsync fastmail";
          onNotifyPost = ''
            ${pkgs.notmuch}/bin/notmuch new
          '';
        };
      };

      # gmail / nibuild accounts kept commented for future use
      # See git history for full configuration
    };
  };

  home.file = {
    # mailcap for handling different content types
    ".mailcap".text = ''
      text/html; ${pkgs.w3m}/bin/w3m -dump -o document_charset=%{charset} '%s'; nametemplate=%s.html; copiousoutput
      # text/html; open %s; nametemplate=%s.html
      # text/html; lynx -assume_charset=%{charset} -display_charset=utf-8 -dump %s; nametemplate=%s.html; copiousoutput
      application/pdf; open %s
      # image/*; open %s
      image/*; kitty +kitten icat '%s'; copiousoutput
      application/msword; open %s
      application/vnd.openxmlformats-officedocument.wordprocessingml.document; open %s
    '';

    # Script to manually sync all mail
    ".local/bin/sync-mail" = {
      text = ''
        #!/usr/bin/env bash

        echo "Syncing email..."

        # Check if already running
        if pgrep -x mbsync >/dev/null; then
          echo "mbsync is already running"
          exit 1
        fi

        # Clean up deleted messages
        ${pkgs.notmuch}/bin/notmuch search --format=text0 --output=files tag:deleted | \
          xargs -0 --no-run-if-empty rm -v

        # Sync all accounts
        ${pkgs.isync}/bin/mbsync -a

        # Update notmuch database
        ${pkgs.notmuch}/bin/notmuch new

        echo "Email sync complete!"
      '';
      executable = true;
    };

    # Script to search email from command line
    ".local/bin/mail-search" = {
      text = ''
        #!/usr/bin/env bash

        if [ $# -eq 0 ]; then
          echo "Usage: mail-search <query>"
          echo "Example: mail-search 'from:example@example.com'"
          exit 1
        fi

        ${pkgs.notmuch}/bin/notmuch search "$@"
      '';
      executable = true;
    };
  };
}
