# MailMate configuration
# REF: https://manual.mailmate-app.com/custom_key_bindings
# REF: https://manual.mailmate-app.com/bundles
# REF: https://tyler.io/2020/04/additional-mailmate-tips/
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
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
    MmHeadersViewWebKitDefaultFontSize = 13;
    MmHeadersViewWebKitStandardFont = "Helvetica";
    MmMessagesWebViewMinimumFontSize = 12;
    MmMessagesWebViewWebKitDefaultFixedFontSize = 13;
    MmMessagesWebViewWebKitDefaultFontSize = 13;
    MmMessagesWebViewWebKitMinimumFontSize = 12;
    MmMessagesWebViewWebKitStandardFont = "Helvetica";

    # Message list behavior
    MmMessagesOutlineOpenMessageOnDoubleClick = true;
    MmMessagesOutlineShowUnreadMessagesInBold = true;
  };

  home.file = {
    # Neovim external editor bundle (edit emails in Neovim via Ghostty)
    # Usage: ⌃⇧O (Control+Shift+O) in composer
    "Library/Application Support/MailMate/Bundles/neovim.mmbundle/info.plist".source =
      ./bundle/info.plist;
    "Library/Application Support/MailMate/Bundles/neovim.mmbundle/Commands/edit.mmCommand".source =
      ./bundle/Commands/edit.mmCommand;
    "Library/Application Support/MailMate/Bundles/neovim.mmbundle/Support/bin/edit" = {
      source = ./bundle/Support/bin/edit;
      executable = true;
    };

    # Custom layouts for conversation/thread navigation
    # Access via: View > Layout > [Layout Name]
    # REF: https://github.com/mailmate/mailmate_manual/wiki/Bundles

    # Conversation + Thread Arcs (Most Popular) - Falkor/MailMate
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/conversation_thread_arcs.plist".source =
      ./layouts/conversation_thread_arcs.plist;

    # Correspondence Arcs - chauncey-garrett/mailmate
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/correspondence-arcs.plist".source =
      ./layouts/correspondence-arcs.plist;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/correspondence-arcs-widescreen.plist".source =
      ./layouts/correspondence-arcs-widescreen.plist;

    # Widescreen with Thread Arcs - parzonka
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/widescreen_with_thread_arcs.plist".source =
      ./layouts/parzonka-widescreen_with_thread_arcs.plist;

    # Threaded View - maxandersen
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/threaded.plist".source =
      ./layouts/maxandersen-threaded.plist;

    # fnurl/mailmatelayouts collection
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/widescreen-thread-correspondence.plist".source =
      ./layouts/fnurl-widescreen-thread-correspondence.plist;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/widescreen-thread-tags.plist".source =
      ./layouts/fnurl-widescreen-thread-tags.plist;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/vertical-thread-correspondence.plist".source =
      ./layouts/fnurl-vertical-thread-correspondence.plist;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/vertical-thread-tags.plist".source =
      ./layouts/fnurl-vertical-thread-tags.plist;

    # Custom keybindings (vim-style navigation)
    "Library/Application Support/MailMate/Resources/KeyBindings/Mega.plist".text = ''
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
  };
}
