# aerc email client configuration
# REF: https://man.sr.ht/~rjarry/aerc/
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  aerc-filters = "${pkgs.aerc}/libexec/aerc/filters";

  # Script to clean up deleted messages before sync
  notmuchCleanup = ''
    # Remove files that are tagged as deleted
    ${pkgs.notmuch}/bin/notmuch search --format=text0 --output=files tag:deleted | \
      xargs -0 --no-run-if-empty rm -v
  '';
in {
  programs.aerc = {
    enable = true;

    # Stylesets (themes)
    stylesets.everforest = builtins.readFile "${inputs.self}/home/common/programs/email/aerc/stylesets/everforest";
    stylesets.megaforest = builtins.readFile "${inputs.self}/home/common/programs/email/aerc/stylesets/megaforest";

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
          ${notmuchCleanup}

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
        thread-prefix-folded = "";
        thread-prefix-unfolded = "";
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
        pinned-tab-marker = "";

        # Column configuration
        index-columns = "date>=,star:1,reply:1,forward:1,name<15%,subject<*,size>=";

        column-star = "{{if .IsFlagged}}󰓎{{end}}";
        column-reply = "{{if .IsReplied}} {{end}}";
        column-forward = "{{if .IsForwarded}} {{end}}";
        column-name = ''{{if eq .Role "sent" }}To: {{.To | names | join ", "}}{{else}}{{.From | names | join ", "}}{{end}}'';
        column-flags = ''{{.Flags | join " "}}'';
        column-subject = ''{{.Style .ThreadPrefix "thread"}}{{.StyleSwitch .Subject (case `^(\[[\w-]+\]\s*)?\[(RFC )?PATCH` "patch")}}'';
        column-size = "{{if .HasAttachment}} {{end}}{{humanReadable .Size}}";
        column-date = "{{.DateAutoFormat .Date.Local}}";

        timestamp-format = "Jan 02, 2006";
        this-day-time-format = "15:04";

        tab-title-account = "{{.Account}}/{{.Folder}} {{if .Exists .Folder}}[  {{if .Unread .Folder}}{{.Unread .Folder | humanReadable}}{{else}}0{{end}}/{{.Exists .Folder| humanReadable}}]{{end}}";
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
            (case "Sent" " ") \
            (case "Trash" "󰩺 ") \
          (default "  ")}} {{.Folder}}
        '';
        dirlist-right = "{{if .Unread}}{{humanReadable .Unread}}/{{end}}{{if .Exists}}{{humanReadable .Exists}}{{end}}";
        dirlist-format = "%n %>r";

        spinner = "◜,◠,◝,◞,◡,◟";

        # Icons
        icon-new = "";
        icon-attachment = "";
        icon-old = "󰔟";
        icon-replied = "";
        icon-flagged = "󰓎";
        icon-deleted = "󰩺";
        icon-unencrypted = "";
        icon-encrypted = "✔";
        icon-signed = "✔";
        icon-signed-encrypted = "✔";
        icon-marked = "✔";
        icon-unknown = "󱎘";
        icon-invalid = "⚠";
        icon-forwarded = "";
        icon-draft = "󰙏";
        icon-sent = "";
        icon-inbox = "";
        icon-calendar = "";
        icon-list = "";
      };

      "ui:folder=Inbox" = {
        sort = "-r date";
      };

      "ui:folder=Archive" = {
        threading-enabled = false;
      };

      "ui:account=combined" = {
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

        column-name = "{{if .From}} {{index (.From | names) 0}}{{else}} malformed email{{end}}";

        column-reply = "{{if .IsReplied}} {{end}}";
        column-forward = "{{if .IsForwarded}} {{end}}";
        column-star = "{{if .IsFlagged}}󰓎 {{end}}";
        column-size = "{{if .HasAttachment}} {{end}}{{humanReadable .Size}}";
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

        # [folders]
        "gi" = ":cf Inbox<Enter>";
        "gu" = ":cf Unread<Enter>";
        "gf" = ":cf Starred<Enter>";
        "ga" = ":cf Archive<Enter>";
        "gs" = ":cf Sent<Enter>";
        "gS" = ":cf Spam<Enter>";
        "gd" = ":cf Drafts<Enter>";
        "gn" = ":cf -a notmuch {{.Folder}}<Enter>";

        # [marks]
        "<Space>" = ":mark -t<Enter>:next<Enter>";
        "v" = ":mark -t<Enter>";
        "V" = ":mark -v<Enter>";

        # [search]
        "\\" = ":filter<space>";
        "<c-s>" = ":search<space>";
        "n" = ":next-result<Enter>";
        "N" = ":prev-result<Enter>";
        "<Esc>" = ":clear<Enter>";

        # [movement]
        "G" = ":select -1<Enter>";
        "gg" = ":select 0<Enter>";

        "j" = ":next<Enter>";
        "J" = ":read<Enter>:next<Enter>";
        "<C-d>" = ":next 50%<Enter>";
        "<Down>" = ":next<Enter>";

        "k" = ":prev<Enter>";
        "K" = ":read<Enter>:prev<Enter>";
        "<C-u>" = ":prev 50%<Enter>";
        "<Up>" = ":prev<Enter>";

        "<C-n>" = ":next-folder<Enter>";
        "<C-p>" = ":prev-folder<Enter>";
        "H" = ":collapse-folder<Enter>";
        "L" = ":expand-folder<Enter>";

        # [threads]
        "T" = '':query -n "query:{{.SubjectBase}}" -a combined thread:\{id:{{.MessageId}}\}<Enter>'';
        "zz" = ":toggle-threads<Enter>";

        # [folds]
        "zc" = ":fold<Enter>";
        "zo" = ":unfold<Enter>";
        "za" = ":fold -t<Enter>";
        "zM" = ":fold -a<Enter>";
        "zR" = ":unfold -a<Enter>";

        # Archive and delete keybindings
        "e" = '':modify-labels -inbox -unread +archive<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/All Mail") (case "fastmail" "fastmail/Archive") (case "nibuild" "nibuild/Archive") (default "Archive")}}<Enter>'';
        "E" = '':unmark -a<Enter>:mark -T<Enter>:modify-labels -inbox -unread +archive<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/All Mail") (case "fastmail" "fastmail/Archive") (case "nibuild" "nibuild/Archive") (default "Archive")}}<Enter>'';
        "d" = '':modify-labels -inbox -unread +trash<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/Trash") (case "fastmail" "fastmail/Trash") (case "nibuild" "nibuild/Trash") (default "Trash")}}<Enter>'';

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

      view = {
        "<C-f>" = ":toggle-key-passthrough<Enter>/";
        "/" = ":query -f -n \"\" -a combined date:1y..<Space>";

        "c" = ":change-tab {{.Account}}<Enter>:compose<Enter>";

        "q" = ":close<Enter>";

        "s" = ":move Starred<Enter>";
        "d" = '':modify-labels -inbox -unread +trash<Enter>:move {{switch (index (.Filename | split "/") 4) (case "gmail" "gmail/[Gmail]/Trash") (case "fastmail" "fastmail/Trash") (case "nibuild" "nibuild/Trash") (default "Trash")}}<Enter>'';
        "D" = ":delete<Enter>";
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
        "A" = ":reply -acA {{index (.Filename | split (\"/\")) 4}}<Enter>";
        "a" = ":reply -acqA {{index (.Filename | split (\"/\")) 4}}<Enter>";
        "R" = ":reply -cA {{index (.Filename | split (\"/\")) 4}}<Enter>";
        "r" = ":reply -cqA {{index (.Filename | split (\"/\")) 4}}<Enter>";
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

  # Create aerc cache directory
  home.file.".cache/aerc/.keep".text = "";
}
