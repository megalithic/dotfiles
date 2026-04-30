# mbsync (isync) - IMAP to maildir sync
# Account-specific config lives in home/common/accounts.nix
{...}: {
  programs.mbsync.enable = true;
}
