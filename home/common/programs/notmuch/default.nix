# notmuch - email indexing and tagging
# Account-specific config lives in home/common/accounts.nix
{
  config,
  pkgs,
  ...
}: let
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
  '';
in {
  programs.notmuch = {
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
}
