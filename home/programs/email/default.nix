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

  aerc-filters = "${pkgs.aerc}/libexec/aerc/filters";
in {
  # MailMate settings
  # REF: https://manual.mailmate-app.com/custom_key_bindings
  home.file."Library/Application\ Support/MailMate/Resources/KeyBindings/Mega.plist".text = ''
    {
        "j" = "selectNextMessageRow:";
        "k" = "selectPreviousMessageRow:";
        "^j" = "selectNextMailboxRow:";
        "^n" = "selectNextCountedMailbox:";
        "^k" = "selectPreviousMailboxRow:";
        "^p" = "selectPreviousCountedMailbox:";
        "l" = "expandThread:";
        ";" = "nextUnreadMessage:";
        "h" = "collapseThread:";
        "g" = { "g" = "selectFirstMessageRow:"; };
        "G" = "selectLastMessageRow:";
        "^f" = "scrollPageDown:";
        "^b " = "scrollPageUp:";
        "^d" = "scrollPageDown:";
        "^u " = "scrollPageUp:";
        "#" = "toggleReadState:";
        "u" = "undo:";
        "^r" = "redo:";

        "`" = { "`" = "markAllAsRead:"; };

        "@\U000A" = "send:"; // ⌘+return
        "@\U000D" = "send:"; // ⌘+enter

        "c"     = "newMessage:";
        "/"     = "searchAllMessages:";
        "n"     = "nextMessage:";
        "p"     = "previousMessage:";
        "e"     = "archive:";
        "s"     = "toggleFlag:";
        "!"     = "moveToJunk:";
        "r"     = "reply:";
        "a"     = "replyAll:";
        "f"     = "forwardMessage:";
        "x"     = "deleteMessage:";
    }
  '';

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

    # aerc email client
    aerc = {
      enable = true;

      stylesets.everforest = builtins.readFile "${inputs.self}/home/programs/email/stylesets/everforest";
      stylesets.megaforest = builtins.readFile "${inputs.self}/home/programs/email/stylesets/megaforest";

      # Extra accounts configuration
      extraAccounts = {
        # Combined view using notmuch
        combined = {
          from = "<noreply@megalithic.io>";
          source = "notmuch://${config.accounts.email.maildirBasePath}";
          maildir-store = config.accounts.email.maildirBasePath;

          # Query map for unified inbox view across all accounts
          # Using HYBRID approach: path-based for Inbox (reliable), tag-based for other views
          query-map = toString (pkgs.writeText "query-map" ''
            # Path-based unified inbox with tag-based exclusions for instant removal
            # This combines physical location check with tag-based filtering for immediate UI updates
            Inbox=(path:fastmail/INBOX/** or path:gmail/Inbox/** or path:nibuild/INBOX/**) and not tag:spam and not tag:trash and not tag:archive

            # Tag-based views for instant updates when moving messages
            Unread=tag:unread and not tag:trash and not tag:spam
            Starred=tag:flagged

            # Folder-specific views (path-based to match physical location)
            Archive=path:fastmail/Archive/** or path:"gmail/[Gmail]/All Mail/**" or path:nibuild/Archive/**
            Sent=path:fastmail/Sent/** or path:"gmail/[Gmail]/Sent Mail/**" or path:nibuild/Sent/**
            Drafts=path:fastmail/Drafts/** or path:"gmail/[Gmail]/Drafts/**" or path:nibuild/Drafts/**
            Trash=path:fastmail/Trash/** or path:"gmail/[Gmail]/Trash/**" or path:nibuild/Trash/**
            Spam=path:fastmail/Spam/** or path:"gmail/[Gmail]/Spam/**" or path:nibuild/Spam/**

            # Tag-based filtered views
            Lists=tag:list and tag:inbox
            GitHub=tag:github and tag:inbox
            Automated=tag:automated and tag:inbox

            # Account-specific inboxes
            Fastmail-Inbox=path:fastmail/INBOX/**
            Gmail-Inbox=path:gmail/Inbox/**
            Nibuild-Inbox=path:nibuild/INBOX/**
          '');

          default = "Inbox";

          # Folder sort order - pin important folders to the top
          folders-sort = "Inbox,Unread,Starred,Archive,Sent,Drafts,Trash,Spam";

          # Check mail command
          check-mail-cmd = toString (pkgs.writeShellScript "check-mail-combined" ''
            #!/usr/bin/env bash

            # Check if mbsync or notmuch is already running
            if pgrep -x mbsync >/dev/null || pgrep -x notmuch >/dev/null; then
              echo "Already running mbsync or notmuch. Exiting..."
              exit 0
            fi

            # Clean up deleted messages first
            ${notmuchPreNew}

            # Sync all accounts
            ${pkgs.isync}/bin/mbsync -a

            # Update notmuch database
            ${pkgs.notmuch}/bin/notmuch new
          '');

          # Timeout for check-mail-cmd (default is 10s, increased to 2 minutes)
          check-mail-timeout = "10m";
          cache-headers = true;
        };

        # Individual account views
        fastmail = {
          from = "<noreply@megalithic.io>";
          source = "notmuch://${config.accounts.email.maildirBasePath}";
          maildir-store = config.accounts.email.maildirBasePath;
          maildir-account-path = "fastmail";
          multi-file-strategy = "act-dir";
          default = "INBOX";
          use-labels = true;
          cache-state = true;
          cache-blobs = true;
          use-envelope-from = true;
          cache-headers = true;
        };

        gmail = {
          from = "<seth.messer@gmail.com>";
          source = "notmuch://${config.accounts.email.maildirBasePath}";
          maildir-store = config.accounts.email.maildirBasePath;
          maildir-account-path = "gmail";
          multi-file-strategy = "act-dir";
          default = "Inbox";
          postpone = "[Gmail]/Drafts";
          copy-to = null;
          cache-headers = true;

          # Gmail folder mapping to simplify folder names in aerc
          folder-map = toString (pkgs.writeText "gmail-folder-map" ''
            [Gmail]/All Mail=All Mail
            [Gmail]/Drafts=Drafts
            [Gmail]/Important=Important
            [Gmail]/Sent Mail=Sent
            [Gmail]/Spam=Spam
            [Gmail]/Starred=Starred
            [Gmail]/Trash=Trash
          '');
        };

        nibuild = {
          from = "<seth@nibuild.com>";
          source = "notmuch://${config.accounts.email.maildirBasePath}";
          maildir-store = config.accounts.email.maildirBasePath;
          maildir-account-path = "nibuild";
          multi-file-strategy = "act-dir";
          default = "INBOX";
          cache-headers = true;
        };
      };

      # Main aerc configuration
      extraConfig = {
        general = {
          default-save-path = "~/Downloads/_email";
          log-file = "~/.cache/aerc/aerc.log";
          unsafe-accounts-conf = true;
          enable-osc8 = true;
        };

        viewer = {
          pager = "${pkgs.less}/bin/less -Rc -+S --wordwrap";
          show-headers = false;
          header-layout = "From,Sender,To,Cc,Bcc,Date,Subject,Labels";
          alternatives = "text/plain,text/html";
          always-show-mime = true;
          parse-http-links = true;
          max-mime-height = 8;
        };

        # Filters for different content types
        filters = {
          "subject,~^\\[PATCH" = "${aerc-filters}/hldiff";
          "text/plain" = "! wrap -w 88 | ${pkgs.aerc}/libexec/aerc/filters/colorize | ${pkgs.delta}/bin/delta --color-only --diff-highlight";
          "text/calendar" = "${pkgs.aerc}/libexec/aerc/filters/calendar | ${pkgs.aerc}/libexec/aerc/filters/colorize";
          "text/html" = "! ${pkgs.aerc}/libexec/aerc/filters/html";
          "text/*" = ''test -n "$AERC_FILENAME" && ${pkgs.bat}/bin/bat -fP --file-name="$AERC_FILENAME" --style=plain || ${pkgs.aerc}/libexec/aerc/filters/colorize'';
          "application/pgp-keys" = "gpg";
          "application/x-*" = ''${pkgs.bat}/bin/bat -fP --file-name="$AERC_FILENAME" --style=auto'';
          "message/delivery-status" = "wrap | ${pkgs.aerc}/libexec/aerc/filters/colorize";
          "message/rfc822" = "wrap | ${pkgs.aerc}/libexec/aerc/filters/colorize";
          ".headers" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        };

        multipart-converters = {
          "text/html" = "${pkgs.pandoc}/bin/pandoc -f gfm -t html --self-contained";
        };

        compose = {
          editor = "$EDITOR +/^$ +nohl ++1";
          # Address book command using khard and maildir-rank-addr
          address-book-cmd = "( khard email --parsable %s; maildir-rank-addr %s ) | sort -u";
          header-layout = "To|From,Cc|Bcc,Subject";
          edit-headers = true;
          reply-to-self = false;
          empty-subject-warning = true;
          no-attachment-warning = "^[^>]*attach(ed|ment)";
          file-picker-cmd = "${pkgs.fd}/bin/fd -t file . ~ | ${pkgs.fzf}/bin/fzf";
        };

        ui = {
          threading-enabled = true;
          threading-by-subject = true;
          show-thread-context = true;

          sort = "";
          sort-thread-siblings = true;

          # Thread prefix customization
          thread-prefix-tip = "";
          thread-prefix-indent = "";
          thread-prefix-stem = "│";
          thread-prefix-limb = "─";
          thread-prefix-folded = "";
          thread-prefix-unfolded = "";
          # thread-prefix-unfolded = "";
          thread-prefix-first-child = "┬";
          thread-prefix-has-siblings = "├";
          thread-prefix-lone = "";
          thread-prefix-orphan = "┌";
          thread-prefix-last-sibling = "└";
          thread-prefix-dummy = "┬";

          styleset-name = "megaforest";
          border-char-vertical = "│";
          border-char-horizontal = "─";
          auto-mark-read = false;
          fuzzy-complete = true;
          completion-delay = "250ms";
          completion-popovers = true;
          sidebar-width = 35;
          mouse-enabled = true;
          message-view-timestamp-format = "2006 Jan 02, 15:04 GMT-0700";
          message-view-this-day-time-format = "Today 15:04";
          message-view-this-week-time-format = "Monday 15:04";
          message-view-this-year-time-format = "January 02 15:04";
          empty-message = "(no messages)";
          empty-dirlist = "(no folders)";
          new-message-bell = false;
          pinned-tab-marker = "";

          # Column configuration
          # Original layout (commented out):
          # index-columns = "star:1,name<15%,reply:1,subject,labels>=,size>=,date>=";
          # column-star = "{{if .IsFlagged}}  {{end}}";
          # column-reply = "{{if .IsReplied}}{{end}}";
          # column-size = "{{if .HasAttachment}}  {{end}}{{humanReadable .Size}}";

          # New layout with explicit icon columns (date first, labels/tags hidden)
          index-columns = "date>=,star:1,reply:1,forward:1,name<15%,subject<*,size>=";
          # index-columns = "date>=,star:1,reply:1,forward:1,flags>4,name<15%,subject<*,size>=";
          # index-columns = date<11,name<17,flags>4,subject<*

          column-star = "{{if .IsFlagged}}󰓎{{end}}";
          column-reply = "{{if .IsReplied}} {{end}}";
          column-forward = "{{if .IsForwarded}} {{end}}";
          column-name = ''{{if eq .Role "sent" }}To: {{.To | names | join ", "}}{{else}}{{.From | names | join ", "}}{{end}}'';
          column-flags = ''{{.Flags | join " "}}'';
          column-subject = ''{{.Style .ThreadPrefix "thread"}}{{.StyleSwitch .Subject (case `^(\[[\w-]+\]\s*)?\[(RFC )?PATCH` "patch")}}'';
          # column-labels hidden from list view but visible in message viewer
          # column-labels = ''{{.StyleMap .Labels (exclude .Folder) (exclude "Important") (default "thread") | join " "}}'';
          column-size = "{{if .HasAttachment}} {{end}}{{humanReadable .Size}}";
          column-date = "{{.DateAutoFormat .Date.Local}}";

          timestamp-format = "Jan 02, 2006";
          this-day-time-format = "15:04";

          tab-title-account = "{{.Account}}/{{.Folder}} {{if .Exists .Folder}}[  {{if .Unread .Folder}}{{.Unread .Folder | humanReadable}}{{else}}0{{end}}/{{.Exists .Folder| humanReadable}}]{{end}}";
          tab-title-composer = ''To:{{(.To | shortmboxes) | join ","}}{{if .Cc}}|Cc:{{(.Cc | shortmboxes) | join ","}}{{end}}|{{if .Bcc}}|Bcc:{{(.Bcc | shortmboxes) | join ","}}{{end}}|{{.Subject}}'';

          dirlist-tree = true;
          dirlist-collapse = 1;
          dirlist-left = ''
            {{switch .Folder \
              (case "Inbox" "󰚇 ") \
              (case "INBOX" "󰚇 ") \
              (case "Unread" "󰇮 ") \
              (case "Starred" "󰓎 ") \
              (case "Archive" "󰀼 ") \
              (case "Drafts" "󰙏 ") \
              (case "Spam" "󱚝 ") \
              (case "Sent" " ") \
              (case "Trash" "󰩺 ") \
            (default "  ")}} {{.Folder}}
          '';
          dirlist-right = "{{if .Unread}}{{humanReadable .Unread}}/{{end}}{{if .Exists}}{{humanReadable .Exists}}{{end}}";
          dirlist-format = "%n %>r";

          # spinner = "⠁,⠂,⠄,⡀,⡁,⡂,⡄,⡅,⡇,⡏,⡗,⡧,⣇,⣏,⣗,⣧,⣯,⣷,⣿,⢿,⣻,⢻,⢽,⣹,⢹,⢸,⠸,⢘,⠘,⠨,⢈,⠈,⠐,⠠,⢀";
          spinner = "◜,◠,◝,◞,◡,◟";

          # Icons
          icon-new = "";
          icon-attachment = "";
          icon-old = "󰔟";
          icon-replied = "";
          icon-flagged = "󰓎";
          icon-deleted = "󰩺";
          icon-unencrypted = "";
          icon-encrypted = "✔";
          icon-signed = "✔";
          icon-signed-encrypted = "✔"; # alts: 
          icon-marked = "✔";
          icon-unknown = "󱎘";
          icon-invalid = "⚠";
          icon-forwarded = "";
          icon-draft = "󰙏";
          icon-sent = "";
          icon-inbox = "";
          icon-calendar = "";
          icon-list = "";
        };

        "ui:folder=Inbox" = {
          sort = "-r date";
        };

        "ui:folder=Archive" = {
          threading-enabled = false;
        };

        "ui:account=combined" = {
          # index-columns = "date<11,account<5,name<17,star>1,size>5,flags>4,subject<*";
          index-columns = "date>=,account<5,star<2,reply<2,forward<2,name<15%,subject<*,size>=";
          column-date = "{{.DateAutoFormat .Date.Local}}";
          column-account = ''
            {{if .Filename}}\
              {{switch (index (.Filename | split "/") 4) \
                (case "gmail" "󰊫") \
                (case "fastmail" "󰇰") \
                (case "nibuild" "󰏆") \
              (default "")}}\
            {{end}}'';

          # 󰀫
          column-name = "{{if .From}} {{index (.From | names) 0}}{{else}} malformed email{{end}}";
          # column-flags = ''{{.Flags | join " "}}'';

          column-reply = "{{if .IsReplied}} {{end}}";
          column-forward = "{{if .IsForwarded}} {{end}}";
          column-star = "{{if .IsFlagged}}󰓎 {{end}}";
          column-size = "{{if .HasAttachment}} {{end}}{{humanReadable .Size}}";
          column-subject = "{{.ThreadPrefix}}{{if .ThreadFolded}}[{{.ThreadCount}}] {{end}}{{.Subject}}";
        };

        "ui:folder~(Sent|Drafts)" = {
          index-columns = "date<11,name<17,flags>4,subject<*";
          column-date = "{{.DateAutoFormat .Date.Local}}";
          column-name = "{{if .To}} To:{{index (.To | names) 0}}{{else}} malformed email{{end}}";
          column-flags = ''{{.Flags | join " "}}'';
          column-subject = "{{.ThreadPrefix}}{{if .ThreadFolded}}[{{.ThreadCount}}] {{end}}{{.Subject}}";
        };

        statusline = {
          status-columns = "left<*,center:=,right>*";
          column-left = "[{{.Account}}/{{.Folder}}] {{.StatusInfo}}";
          column-center = "{{.PendingKeys}}";
          column-right = ''{{.TrayInfo}} | {{.Style cwd "cyan"}}'';
        };
      };

      extraBinds = {
        global = {
          "<C-h>" = ":prev-tab<Enter>";
          "<C-l>" = ":next-tab<Enter>";
          "?" = ":help keys<Enter>";
          "<C-c><C-c>" = ":quit<Enter>";
          # "<C-q>" = ":prompt '󰈆 quit? ' quit<Enter>";
          "<C-z>" = ":suspend<Enter>";
          "<C-r>" = ":check-mail<Enter>";
          "<C-g>" = ":menu -adc fzf :cf -a<Enter>";
          "<C-t>" = ":term<Enter>";
        };

        messages = {
          "q" = ":prompt '󰈆 quit? ' quit<Enter>";
          "<Enter>" = ":read<Enter>:view<Enter>";
          "o" = ":view<Enter>";
          "c" = ":compose<Enter>";
          "C" = ":compose<Enter>";

          # [folders] -----------------------------------------------------------------------------

          "gi" = ":cf Inbox<Enter>";
          "gu" = ":cf Unread<Enter>";
          "gf" = ":cf Starred<Enter>"; # "flagged"
          "ga" = ":cf Archive<Enter>";
          "gs" = ":cf Sent<Enter>";
          "gS" = ":cf Spam<Enter>";
          "gd" = ":cf Drafts<Enter>";
          "gn" = ":cf -a notmuch {{.Folder}}<Enter>";

          # [marks] -------------------------------------------------------------------------------

          "<Space>" = ":mark -t<Enter>:next<Enter>";
          # "<tab>" = ":mark -t<Enter>:next<Enter>";
          "v" = ":mark -t<Enter>";
          "V" = ":mark -v<Enter>";

          # [search] ------------------------------------------------------------------------------

          "\\" = ":filter<space>";
          "<c-s>" = ":search<space>";
          "n" = ":next-result<Enter>";
          "N" = ":prev-result<Enter>";
          "<Esc>" = ":clear<Enter>";

          # [movement] ----------------------------------------------------------------------------

          "G" = ":select -1<Enter>"; # select last mail
          "gg" = ":select 0<Enter>"; # select first mail

          "j" = ":next<Enter>";
          "J" = ":read<Enter>:next<Enter>";
          # "<C-j>" = ":next-folder<Enter>";
          "<C-d>" = ":next 50%<Enter>";
          "<Down>" = ":next<Enter>";

          "k" = ":prev<Enter>";
          "K" = ":read<Enter>:prev<Enter>";
          # "<C-k>" = ":prev-folder<Enter>";
          "<C-u>" = ":prev 50%<Enter>";
          "<Up>" = ":prev<Enter>";

          "<C-n>" = ":next-folder<Enter>";
          "<C-p>" = ":prev-folder<Enter>";
          "H" = ":collapse-folder<Enter>";
          "L" = ":expand-folder<Enter>";

          # [threads] -----------------------------------------------------------------------------

          "T" = '':query -n "query:{{.SubjectBase}}" -a combined thread:\{id:{{.MessageId}}\}<Enter>'';
          "zz" = ":toggle-threads<Enter>";

          # [folds] -------------------------------------------------------------------------------

          "zc" = ":fold<Enter>";
          "zo" = ":unfold<Enter>";
          "za" = ":fold -t<Enter>";
          "zM" = ":fold -a<Enter>";
          "zR" = ":unfold -a<Enter>";

          # "<tab>" = ":fold -t<Enter>";

          # Archive and delete keybindings
          # Use modify-labels for instant UI update, then move files for proper maildir organization
          "e" = '':modify-labels -inbox -unread +archive<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/All Mail") (case "fastmail" "fastmail/Archive") (case "nibuild" "nibuild/Archive") (default "Archive")}}<Enter>'';
          "E" = '':unmark -a<Enter>:mark -T<Enter>:modify-labels -inbox -unread +archive<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/All Mail") (case "fastmail" "fastmail/Archive") (case "nibuild" "nibuild/Archive") (default "Archive")}}<Enter>'';
          "d" = '':modify-labels -inbox -unread +trash<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/Trash") (case "fastmail" "fastmail/Trash") (case "nibuild" "nibuild/Trash") (default "Trash")}}<Enter>'';

          # "y" = ":archive flat<Enter>";
          # "Y" = ":unmark -a<Enter>:mark -T<Enter>:archive flat<Enter>";
          # "x" = ":mv Trash<Enter>";
          # "D" = ":unmark -a<Enter>:mark -T<Enter>:move Trash<Enter>";

          "rr" = ":reply -a<Enter>";
          "rq" = ":reply -aq<Enter>";
          "Rr" = ":reply<Enter>";
          "Rq" = ":reply -q<Enter>";

          "$" = ":term<space>";
          "!" = ":term<space>";
          "|" = ":pipe<space>";

          "P" = ":pipe -m git am -3<Enter>";
          "pa" = ":pipe -m git apply-series -a<Enter>";
        };

        "messages:folder=Drafts" = {
          "<Enter>" = ":recall<Enter>";
        };

        "messages:folder=Trash" = {
          "d" = ":choose -o y 'Really delete this message' delete-message<Enter>";
          "D" = ":delete<Enter>";
        };

        # Removed redundant messages:account=combined section
        # The general messages section already handles combined account with the same logic

        view = {
          "<C-f>" = ":toggle-key-passthrough<Enter>/";
          "/" = ":query -f -n \"\" -a combined date:1y..<Space>";

          "c" = ":change-tab {{.Account}}<Enter>:compose<Enter>";

          "q" = ":close<Enter>";

          "s" = ":move Starred<Enter>";
          # Move to account-specific Trash folder
          "d" = '':modify-labels -inbox -unread +trash<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/Trash") (case "fastmail" "fastmail/Trash") (case "nibuild" "nibuild/Trash") (default "Trash")}}<Enter>'';
          "D" = ":delete<Enter>";
          # Move to account-specific Archive folder
          "e" = '':modify-labels -inbox -unread +archive<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/All Mail") (case "fastmail" "fastmail/Archive") (case "nibuild" "nibuild/Archive") (default "Archive")}}<Enter>'';
          "E" = '':unmark -a<Enter>:mark -T<Enter>:modify-labels -inbox -unread +archive<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/All Mail") (case "fastmail" "fastmail/Archive") (case "nibuild" "nibuild/Archive") (default "Archive")}}<Enter>'';

          "o" = ":open<Enter>";
          "S" = ":save<space>";
          "|" = ":pipe<space>";

          "f" = ":forward<Enter>";
          "rr" = ":reply -a<Enter>";
          "rq" = ":reply -aq<Enter>";
          "Rr" = ":reply<Enter>";
          "Rq" = ":reply -q<Enter>";

          "H" = ":toggle-headers<Enter>";
          "J" = ":next<Enter>";
          "K" = ":prev<Enter>";

          "yf" = ":exec sh -c 'notmuch search --output=files id:{{.MessageId}} | clip'<Enter>";
        };

        "view:account=combined" = {
          # Account-specific reply keybindings (use -A flag to specify account from filename)
          "A" = ":reply -acA {{index (.Filename | split (\"/\")) 4}}<Enter>";
          "a" = ":reply -acqA {{index (.Filename | split (\"/\")) 4}}<Enter>";
          "R" = ":reply -cA {{index (.Filename | split (\"/\")) 4}}<Enter>";
          "r" = ":reply -cqA {{index (.Filename | split (\"/\")) 4}}<Enter>";

          # Note: d, e, E keybindings inherited from general view section
        };

        "view:folder=Trash" = {
          "D" = ":delete<Enter>";
        };

        "view::passthrough" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<Esc>" = ":toggle-key-passthrough<Enter>";
        };

        compose = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "$complete" = "<C-o>";

          "<C-n>" = ":prev-field<Enter>";
          "<C-p>" = ":next-field<Enter>";

          "<tab>" = ":next-field<Enter>";
          "<backtab>" = ":prev-field<Enter>";
        };

        "compose::review" = {
          "y" = ":send<Enter>";
          "n" = ":abort<Enter>";
          "v" = ":preview<Enter>";
          "p" = ":postpone<Enter>";
          "q" = ":choose -o d discard abort -o p postpone postpone<Enter>";
          "e" = ":edit<Enter>";
          "a" = ":attach<space>";
          "d" = ":detach<space>";
        };
      };
    };

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
    ".cache/aerc/.keep".text = "";

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
