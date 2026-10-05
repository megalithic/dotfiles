# avwatchweb

Manifest V3, plain JavaScript, no build step. The service worker sends validated per-tab events to `com.megadots.avwatchd`. Meeting/user-media state is limited to configured meeting URLs; playback and display-share state accepts HTTP(S) tabs.

The main-world hook observes capture APIs and media element playback without
reading page text, titles, sources, participant names, or media-session metadata.
`mise run setup:avwatchd` generates the Helium native-host manifest with the current `$DOTFILES_DIR` path and restricts it to extension ID `ogfaajbfamngmlmkppahdpkoliobdemk`.
