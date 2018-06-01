## [ Hammerspoon ](https://www.hammerspoon.org)

### What even is this?

The simplest answer, is that Hammerspoon is a Lua-based automation framework for
your macOS-based computer. It has a robust and well-documented Lua layer on top
of the macOS core libraries and APIs.

### So, what does my config do?

- **Push-to-Talk**: includes a handy menubar icon for current "talk" status. Bound to `alt+cmd`.

- **Spotify Controls**: simple keybindings to handle Play/Pause, Next, Previous;
as well as Volume Up and Volume Down. Bound to `ctrl+shift+[`, `ctrl+shift+]`,
`ctrl+shift+\`, `ctrl+shift+=`, `ctrl+shift+-`.

- **Computer Locking**: locks your computer with a set of key commands. Bound to
`cmd+ctrl+shift+l`.

- **Application Toggling**:
  * Finder: ``ctrl+```
  * Chrome: ``cmd+```
  * Kitty: `ctrl+space`
  * Slack: `cmd+ctrl+shift+s`
  * Spark: `cmd+ctrl+shift+m`
  * Zoom: `cmd+ctrl+shift+z`
  * Messages: `cmd+shift+m`
  * YakYak: `ctrl+shift+m`
  * Spotify: `cmd+shift+8`

- **Window Management**:
  * Automatic window placement, can be configured in `config.lua`.
  * Manual window placement and sizing. Bound to `cmd+ctrl+j/k/l/h`.

- **Automatic USB**:
  * When docking my laptop (plugging in the TB3 cable, aka using the laptop in
  desktop mode), it automatically switches my Karabiner-Elements profile to the
  one for my Vortex Pok3r mechanical keyboard. It automatically turns off WiFi.
  It automatically switches my audio output devices to my AudioEngine D1.
  It does the reverse to all these things to switch everything to be tied to
  my laptop in laptop mode.

- **[Home Assistant](https://www.home-assistant.io/) Integration**:
  * When logging into the computer, and I'm at home, it will fire off certain
  shell scripts to my Home Assistant server to handle device control in my
  office (lights, etc). Home Assistant does this based on other factors, like
  the weather, time of day, etc.

- **Other Things**: I'm sure I missed some of the other things I've added or
modified. The above documents the most notable and most used Hammerspoon automations.
