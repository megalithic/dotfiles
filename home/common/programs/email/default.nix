# REFS:
# - aerc/general mail: https://bence.ferdinandy.com/2023/07/20/email-in-the-terminal-a-complete-guide-to-the-unix-way-of-email
# - afew: https://github.com/heph2/infra/blob/main/hosts/freya/home.nix#L137-L172[27;5;106~
# - lots of useful mail functionality: https://github.com/RaitoBezarius/nixos-home/blob/master/emails/default.nix
# - lots more useful mail things: https://github.com/stites/configs/blob/master/programs/mail.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  ca-bundle_path = "${pkgs.cacert}/etc/ssl/certs/";
  ca-bundle_crt = "${ca-bundle_path}/ca-bundle.crt";

  # newMailNotification = pkgs.writeShellScript "new-mail-notification" ''
  #   #!/usr/bin/env bash
  #
  #   osascript -e 'display notification "New mail arrived" with title "Email" sound name "Glass"'
  # '';

  notmuchPreNew = pkgs.writeShellScript "notmuch-pre-new_remove_tagged_deleted" ''
    #!/usr/bin/env bash

    # Remove files that are tagged as deleted
    ${pkgs.notmuch}/bin/notmuch search --format=text0 --output=files tag:deleted | \
      xargs -0 --no-run-if-empty rm -v
  '';

  notmuchPostNew = pkgs.writeShellScript "notmuch-post-new_autotag" ''
    #!/usr/bin/env bash

    # Auto-tag by account
    ${pkgs.notmuch}/bin/notmuch tag +fastmail -- path:fastmail/** and tag:new
    ${pkgs.notmuch}/bin/notmuch tag +gmail -- path:gmail/** and tag:new
    ${pkgs.notmuch}/bin/notmuch tag +nibuild -- path:nibuild/** and tag:new

    # Auto-tag by folder
    ${pkgs.notmuch}/bin/notmuch tag +sent -inbox -- 'folder:Sent or folder:"[Gmail]/Sent Mail"' and tag:new
    ${pkgs.notmuch}/bin/notmuch tag +drafts -inbox -- 'folder:Drafts or folder:"[Gmail]/Drafts"' and tag:new
    ${pkgs.notmuch}/bin/notmuch tag +archive -inbox -- 'folder:Archive or folder:"[Gmail]/All Mail"' and tag:new
    ${pkgs.notmuch}/bin/notmuch tag +spam -inbox -- 'folder:Spam or folder:"[Gmail]/Spam"' and tag:new
    ${pkgs.notmuch}/bin/notmuch tag +trash -inbox -- 'folder:Trash or folder:"[Gmail]/Trash"' and tag:new

    # Remove 'new' tag
    ${pkgs.notmuch}/bin/notmuch tag -new -- tag:new

    # Tag sent mail with recipient info (for better searching)
    ${pkgs.notmuch}/bin/notmuch tag +sent-to-self -- tag:sent and to:seth@megalithic.io

    # Auto-tag mailing lists (common patterns)
    ${pkgs.notmuch}/bin/notmuch tag +list -- tag:inbox and 'List-Id:*'

    # Mark GitHub notifications
    ${pkgs.notmuch}/bin/notmuch tag +github -- from:notifications@github.com

    # Mark automated emails
    ${pkgs.notmuch}/bin/notmuch tag +automated -- from:noreply or from:no-reply or from:donotreply

    # osascript -e 'display notification "New mail arrived" with title "Email" sound name "Glass"'
  '';
in {
  imports = [
    ./mailmate
    ./aerc
  ];

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
        aerc.enable = true;
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

      # gmail = {
      #   primary = false;
      #   realName = "Seth Messer";
      #   address = "seth.messer@gmail.com";
      #   userName = "seth.messer@gmail.com";
      #   passwordCommand = "op read op://Shared/aw6tbw4va5bpnippcdqh2mkfq4/tui";
      #   folders = {
      #     inbox = "Inbox";
      #     sent = "[Gmail]/Sent Mail";
      #     trash = "[Gmail]/Trash";
      #     drafts = "[Gmail]/Drafts";
      #   };
      #   flavor = "gmail.com";
      #   signature = {
      #     text = ''
      #       Regards,
      #       Seth Messer
      #       seth.messer@gmail.com
      #     '';
      #     showSignature = "append";
      #   };
      #
      #   aerc.enable = true;
      #   notmuch.enable = true;
      #   mbsync = {
      #     enable = true;
      #     create = "both";
      #     expunge = "both";
      #     remove = "both";
      #     extraConfig.channel = {
      #       CopyArrivalDate = "yes";
      #     };
      #   };
      #
      #   msmtp = {
      #     enable = true;
      #     extraConfig = {
      #       tls_starttls = "on";
      #       logfile = "~/.cache/msmtp/msmtp.log";
      #     };
      #   };
      #
      #   imapnotify = {
      #     enable = true;
      #     boxes = ["Inbox"];
      #     onNotify = "${pkgs.isync}/bin/mbsync gmail";
      #     onNotifyPost = ''
      #       ${pkgs.notmuch}/bin/notmuch new
      #       ${newMailNotification}
      #     '';
      #   };
      # };
      #
      # nibuild = {
      #   primary = false;
      #   address = "seth@nibuild.com";
      #   realName = "Seth Messer";
      #   userName = "seth@nibuild.com";
      #   passwordCommand = "op read op://Shared/xk72bkenziy7wxjmxkpxze2nsi/password";
      #   flavor = "plain";
      #   aliases = ["smesser@nibuild.com"];
      #   imap = {
      #     host = "mail.nibuild.com";
      #     tls.enable = true;
      #     port = 993;
      #   };
      #   smtp = {
      #     host = "smtp.nibuild.com";
      #     tls.enable = true;
      #     port = 465;
      #   };
      #   signature = {
      #     text = ''
      #       Regards,
      #       Seth Messer
      #       seth@nibuild.com
      #     '';
      #     showSignature = "append";
      #   };
      #
      #   aerc.enable = true;
      #   notmuch.enable = true;
      #   mbsync = {
      #     enable = true;
      #     create = "both";
      #     expunge = "both";
      #     remove = "both";
      #     extraConfig.channel = {
      #       CopyArrivalDate = "yes";
      #     };
      #   };
      #
      #   msmtp = {
      #     enable = true;
      #     extraConfig = {
      #       tls_starttls = "on";
      #       logfile = "~/.cache/msmtp/msmtp.log";
      #     };
      #   };
      #
      #   imapnotify = {
      #     enable = true;
      #     boxes = ["INBOX"];
      #     onNotify = "${pkgs.isync}/bin/mbsync nibuild";
      #     onNotifyPost = ''
      #       ${pkgs.notmuch}/bin/notmuch new
      #       ${newMailNotification}
      #     '';
      #   };
      # };
    };
  };

  # Program configurations
  programs = {
    # mbsync for syncing emails
    mbsync.enable = true;

    # msmtp for sending emails with queue support (msmtpq)
    msmtp = {
      enable = true;
      # Enable offline queue - use configContent with mkBefore (extraConfig is deprecated)
      configContent = lib.mkBefore ''
        # Global msmtp configuration
        defaults
        auth on
        tls on
        tls_trust_file ${ca-bundle_crt}

        # Log all transactions
        logfile ~/.cache/msmtp/msmtp.log
      '';
    };

    # notmuch for email indexing and search
    notmuch = {
      enable = true;

      # Initial tagging for new emails
      new = {
        tags = [
          "unread"
          "inbox"
          "new"
        ];
      };

      # Exclude these tags from search by default
      search = {
        excludeTags = [
          "deleted"
          "trash"
          "spam"
        ];
      };

      # query = {
      #   "inbox" = "tag:inbox and tag:unread";
      #   "sent" = "tag:sent";
      #   "archive" = "not tag:inbox";
      #   "github" = "tag:github or from:notifications@github.com";
      #   "urgent" = "tag:urgent";
      # };

      # Synchronize maildir flags with notmuch tags
      maildir = {
        synchronizeFlags = true;
      };

      # Hooks for automatic tagging and cleanup
      hooks = {
        postNew = toString notmuchPostNew;
        preNew = toString notmuchPreNew;
      };

      # Extra configuration
      extraConfig = {
        # # Search configuration
        # search = {
        #   # Exclude these tags from search results
        #   exclude_tags = "deleted;spam;trash";
        # };

        # Database configuration
        database = {
          # Store database in maildir
          path = config.accounts.email.maildirBasePath;
        };

        # User information
        user = {
          name = "Seth Messer";
          primary_email = "seth@megalithic.io";
          other_email = "seth.messer@gmail.com;seth@nibuild.com;sethmesser@fastmail.com";
        };
      };
    };

    # aerc configuration moved to ./aerc/default.nix

    # Address book integration
    khard = {
      enable = true;
      settings = {
        "contact table" = {
          display = "formatted_name";
          preferred_phone_number_type = ["pref" "mobile" "cell"];
          preferred_email_address_type = ["pref" "work" "home"];
        };
      };
    };
  };

  # Create necessary directories and scripts
  home.file = {
    # Create log directories
    ".cache/msmtp/.keep".text = "";
    # aerc cache dir is created in ./aerc/default.nix

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
        ${notmuchPreNew}

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
