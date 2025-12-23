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
}: let
  # Fetch custom layouts from upstream sources with hash verification
  # These will be cached in the Nix store and only re-fetched if hashes change
  layouts = {
    conversation-thread-arcs = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Falkor/MailMate/master/Layouts/Mailboxes/conversation_thread_arcs.plist";
      sha256 = "af1917948c7d6ee0ea46edd45fecf792fc967cdf858885c97a7f659a108b9e91";
    };

    correspondence-arcs = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/chauncey-garrett/mailmate/master/Layouts/Mailboxes/correspondence-arcs.plist";
      sha256 = "ce373a86ed1a3a4fc86cab8295a1f0dedcc7292a35da0ca395f31552bc59a67e";
    };

    correspondence-arcs-widescreen = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/chauncey-garrett/mailmate/master/Layouts/Mailboxes/correspondence-arcs-widescreen.plist";
      sha256 = "a6a94591e7e6d550e2c729b536c30ccca389ded29695f6e7574c20648d563982";
    };

    parzonka-widescreen-thread-arcs = pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/parzonka/4707302/raw/widescreen_with_thread_arcs.plist";
      sha256 = "b8c3bb41ce580a69430f7576531857ea3fb0dd0f4ee976dabc9886732a2f1e94";
    };

    maxandersen-threaded = pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/maxandersen/40b70477ad8594565f24f9b7b45abf5d/raw/threaded.plist";
      sha256 = "db79e22a27d4eb89a3b74a6b190454e3c63724d250ffe77d934b4e287cdbfe8c";
    };

    fnurl-widescreen-thread-correspondence = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/fnurl/mailmatelayouts/master/Resources/Layouts/Mailboxes/widescreenThreadCorr.plist";
      sha256 = "e7385880849ce0121bf6b5b0493929f490cb4b47868af1aaa942eef4dbe4fa72";
    };

    fnurl-widescreen-thread-tags = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/fnurl/mailmatelayouts/master/Resources/Layouts/Mailboxes/widescreenThreadTag.plist";
      sha256 = "5eaafa88483a8bca51960b469b01f320f770eb43f78faffc6172371fe5969a8d";
    };

    fnurl-vertical-thread-correspondence = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/fnurl/mailmatelayouts/master/Resources/Layouts/Mailboxes/verticalThreadCorr.plist";
      sha256 = "3d2380ce02bce873fec28714bcc9747873ad6fe3d6d622e0dc0a91d79918791e";
    };

    fnurl-vertical-thread-tags = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/fnurl/mailmatelayouts/master/Resources/Layouts/Mailboxes/verticalThreadTag.plist";
      sha256 = "823334d656d3a9f8cc4ae4bac0fca9d24aadf82b26851ef0369ee465320b1ba3";
    };
  };
in {
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
      ./neovim_bundle/info.plist;
    "Library/Application Support/MailMate/Bundles/neovim.mmbundle/Commands/edit.mmCommand".source =
      ./neovim_bundle/Commands/edit.mmCommand;
    "Library/Application Support/MailMate/Bundles/neovim.mmbundle/Support/bin/edit" = {
      source = ./neovim_bundle/Support/bin/edit;
      executable = true;
    };

    # Custom layouts for conversation/thread navigation (fetched from upstream)
    # Access via: View > Layout > [Layout Name]
    # REF: https://github.com/mailmate/mailmate_manual/wiki/Bundles

    # Conversation + Thread Arcs (Most Popular) - Falkor/MailMate
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/conversation_thread_arcs.plist".source =
      layouts.conversation-thread-arcs;

    # Correspondence Arcs - chauncey-garrett/mailmate
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/correspondence-arcs.plist".source =
      layouts.correspondence-arcs;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/correspondence-arcs-widescreen.plist".source =
      layouts.correspondence-arcs-widescreen;

    # Widescreen with Thread Arcs - parzonka
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/widescreen_with_thread_arcs.plist".source =
      layouts.parzonka-widescreen-thread-arcs;

    # Threaded View - maxandersen
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/threaded.plist".source =
      layouts.maxandersen-threaded;

    # fnurl/mailmatelayouts collection
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/widescreen-thread-correspondence.plist".source =
      layouts.fnurl-widescreen-thread-correspondence;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/widescreen-thread-tags.plist".source =
      layouts.fnurl-widescreen-thread-tags;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/vertical-thread-correspondence.plist".source =
      layouts.fnurl-vertical-thread-correspondence;
    "Library/Application Support/MailMate/Resources/Layouts/Mailboxes/vertical-thread-tags.plist".source =
      layouts.fnurl-vertical-thread-tags;

    # Custom keybindings (vim-style navigation)
    # REF:
    # https://gist.github.com/driesg/7786266
    # ,https://github.com/sheriferson/dotfiles/blob/main/MailMate/Resources/KeyBindings/sherif_mm_keys.plist
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
          "m" = "toggleReadState:";
          "u" = "undo:";
          "^r" = "redo:";

          # "j" = { "markAsJunk:", , "moveToMailbox:",'/Junk' };
          # "j" = "markAsJunk:";
          # "J" = { "markAsNotJunk:", "moveToMailbox:",'/Inbox' };
          # "J" = "markAsNotJunk:";
          "^g" = "goToMailbox:";

          # "g" = {
          #   "a" = ( "goToMailbox:", "ALL_MESSAGES" );
          #   "i" = ( "goToMailbox:", "INBOX" );
          #   "s" = ( "goToMailbox:", "SENT" );
          #   "f" = ( "goToMailbox:", "FLAGGED" );
          #   # "=" = ( "goToMailbox:", "BDC80A1A-8F60-4B3C-8EF4-0ECF19B62B58" ); // Action smart mailbox
          #   "l" = "goToMailbox:"; // Don't really use this. ⌘t still works
          #   "1" = ( "makeFirstResponder:", "mailboxesOutline" );
          #   "2" = ( "makeFirstResponder:", "mainOutline" );
          #   "3" = ( "makeFirstResponder:", "messageView" );
          # };

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
