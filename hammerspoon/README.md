## [ Hammerspoon ](https://www.hammerspoon.org)

### What even is this?

The simplest answer, is that Hammerspoon is a Lua-based automation framework for
your macOS-based computer. It has a robust and [well-documented](http://www.hammerspoon.org/docs/) Lua layer on top
of the macOS core libraries and APIs.

### So, what does my [config](hammerspoon.symlink/config.lua) do?

- **Push-to-Talk**: includes a handy menubar icon for current "talk" status. Bound to holding `alt+cmd` to talk.

- **Spotify Controls**: simple keybindings to handle Play/Pause, Next, Previous.
Bound to `ctrl+shift+[`, `ctrl+shift+]`, `ctrl+shift+\`.

- **Computer Locking**: locks your computer with a set of key commands. Bound to
`cmd+ctrl+shift+l`.

- **Application Toggling**:
  * Finder: `ctrl+backtick`
  * Chrome: `cmd+backtick`
  * Kitty: `ctrl+space`
  * Slack: `cmd+ctrl+shift+s`
  * Spark: `cmd+ctrl+shift+m`
  * Zoom: `cmd+ctrl+shift+z`
  * Messages: `cmd+shift+m`
  * YakYak: `ctrl+shift+m`
  * Spotify: `cmd+shift+8`

- **Window Management**:
  * Automatic window placement, can be configured in `config.lua`.
  * Manual window placement and sizing (with chaining to different sections of
    the screen as you repeat the keypresses). Bound to `cmd+ctrl+j/k/l/h`.

- **Automatic USB**:
  * When docking my laptop (plugging in the TB3 cable, aka using the laptop in
  desktop mode), it automatically switches:
    - the Karabiner-Elements profile to `pok3r` (Vortex Pok3r mechanical keyboard)
    - turns off WiFi
    - switches audio output to `AudioEngine D1` DAC
    - switches audio input to `Logitech Webcam C930e` DAC
  * It will reverse to the internal/built-in devices of my MacBook Pro when
  unplugging.

- **[Home Assistant](https://www.home-assistant.io/) Integration**:
  * When logging into the computer, and I'm at home, it will fire off certain
  shell scripts to my Home Assistant server to handle device control in my
  office (lights, etc). Home Assistant does this based on other factors, like
  the weather, time of day, etc.

- **Other Things**:
  * I'm sure I missed some of the other things I've added or
  modified. The above documents the most notable and most used Hammerspoon automations.
  * Be sure to check out the main [config](hammerspoon.symlink/config.lua) to see what all is setup right now.
