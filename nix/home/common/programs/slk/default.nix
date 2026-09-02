{ pkgs, ... }:

{
  home.packages = [ pkgs.slk ];

  # slk reads its config from ~/.config/slk/config.toml.
  # Workspace auth tokens are intentionally not managed here; add them with:
  #   slk --add-workspace
  xdg.configFile."slk/config.toml".text = ''
    [general]
    use_slack_sections = true

    [appearance]
    theme = "dracula"
    timestamp_format = "3:04 PM"
    image_protocol = "auto"
    max_image_rows = 20

    [animations]
    enabled = true
    smooth_scrolling = true
    typing_indicators = true

    [notifications]
    enabled = true
    on_mention = true
    on_dm = true
    on_keyword = []

    [cache]
    message_retention_days = 30
    max_db_size_mb = 500
    max_image_cache_mb = 200
  '';
}
