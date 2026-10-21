# MailMate configuration
# REF: https://manual.mailmate-app.com/custom_key_bindings
# REF: https://tyler.io/2020/04/additional-mailmate-tips/
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # MailMate package - IMAP email client
  # Built with mkApp, copied to /Applications for licensing
  mailmate =
    lib.mega.mkApp
      {
        inherit pkgs lib;
        inherit (pkgs) stdenvNoCC;
      }
      {
        pname = "mailmate";
        version = "5673";
        appName = "MailMate.app";
        src = {
          url = "https://updates.mailmate-app.com/archives/MailMate_r5673.tbz";
          sha256 = "2dc1069207d85a92c3a7000f019f8e4df88f123d2ffce4fdce17256d43c99cba";
        };
        binaries = [ ]; # emate is inside app bundle, symlinked separately below
        appLocation = "copy"; # Needs /Applications for licensing
        desc = "IMAP email client";
        homepage = "https://freron.com/";
      };
in
{
  # emate CLI - symlink from app bundle in /Applications
  home.file.".local/bin/emate".source =
    config.lib.file.mkOutOfStoreSymlink "/Applications/MailMate.app/Contents/Resources/emate";

  # macOS defaults for MailMate
  # These were previously in modules/system.nix under system.defaults.CustomUserPreferences
  targets.darwin.defaults."com.freron.MailMate" = {
    # Update channel
    SoftwareUpdateChannel = "beta";
    MmShowTips = "never";

    # Custom keybindings (vim-style)
    MmCustomKeyBindingsEnabled = true;
    MmCustomKeyBindingsName = "Mega";

    # Composer behavior
    MmComposerInitialFocus = "alwaysTextView";

    # Display preferences
    MmShowAttachmentsFirst = true;
    MmSingleMessageWindowClosesAfterMove = true;

    # Font settings
    MmHeadersViewWebKitDefaultFontSize = 14;
    MmHeadersViewWebKitStandardFont = "Helvetica";
    MmMessagesWebViewMinimumFontSize = 14;
    MmMessagesWebViewWebKitDefaultFixedFontSize = 14;
    MmMessagesWebViewWebKitDefaultFontSize = 14;
    MmMessagesWebViewWebKitMinimumFontSize = 14;
    MmMessagesWebViewWebKitStandardFont = "Helvetica";

    # Message list behavior
    MmMessagesOutlineOpenMessageOnDoubleClick = true;
    MmMessagesOutlineShowUnreadMessagesInBold = true;
  };

  home.file = {
    # Custom keybindings (vim-style navigation)
    # REF:
    # https://gist.github.com/driesg/7786266
    # ,https://github.com/sheriferson/dotfiles/blob/main/MailMate/Resources/KeyBindings/sherif_mm_keys.plist
    "Library/Application Support/MailMate/Resources/KeyBindings/Mega.plist".text = ''
      {
          // ALL_JUNK_DELETED = every mailbox in every account; refreshMailbox: drops read messages kept in Unread
          "^R" = ( "synchronize:", "ALL_JUNK_DELETED", "refreshMailbox:" );
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
          "m" = "toggleReadState:";
          "u" = "undo:";
          "^r" = "redo:";

          "`" = { "`" = "markAllAsRead:"; };

          "@\U000A" = "send:"; // ⌘+return
          "@\U000D" = "send:"; // ⌘+enter

          "c"     = "newMessage:";
          "/"     = "searchAllMessages:";
          "n"     = "nextMessage:";
          "p"     = "previousMessage:";
          "e"     = ( "setTag:", "\\Seen", "archive:", "refreshMailbox:" );
          "s"     = "toggleFlag:";
          "!"     = "moveToJunk:";
          "r"     = "reply:";
          "a"     = "replyAll:";
          "f"     = "forwardMessage:";
          "x"     = "deleteMessage:";
      }
    '';
  };

  # Register with mkAppActivation for /Applications copy
  mega.customApps = [ mailmate ];
}
