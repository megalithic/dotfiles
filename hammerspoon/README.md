## [ Hammerspoon ](https://www.hammerspoon.org)⚭

### What even is this?

The simplest answer is that Hammerspoon is a Lua-based automation framework for
your macOS-based computer. It has a robust and [well-documented](http://www.hammerspoon.org/docs/) Lua layer on top
of the macOS core libraries and APIs.

### So, what does my [config](hammerspoon.symlink/config.lua) do (it's the primary setup for everything)?

y **Push-to-Talk (PTT)**: includes a handy menubar icon for current "talk" status. Bound to holding `opt+cmd` to talk.

- **Spotify Controls**: simple keybindings to handle Play/Pause, Next, Previous.
  Bound to `ctrl+shift+[`, `ctrl+shift+]`, `ctrl+shift+\`.

- **Computer Locking**: locks your computer with a set of key commands. Bound to
  `cmd+ctrl+shift+l`.

- **Accidental app quitting protection**: prevents accidental app quitting,
  makes you hit `cmd+q` twice.

- **Application Toggling** (for example):

  - Finder: `ctrl+backtick`
  - Brave: `cmd+backtick`
  - Kitty: `ctrl+space`
  - Slack: `cmd+ctrl+shift+s`
  - Spark: `cmd+ctrl+shift+m`
  - Zoom: `cmd+ctrl+shift+z`
  - Messages: `cmd+shift+m`
  - Spotify: `cmd+shift+8`

* **App-specific customization**:

  - apps can define their own custom `handler` function to be executed when they are active,
    for example, custom keybinding (see Slack in config.lua)
  - apps can auto set dnd and slack status modes
  - apps can enable/disable QuitGuard™
  - apps can auto-hide after n-minute interval
  - apps can auto-quit after n-minute interval

- **Window Management**:

  - Automatic window placement, as presently configured in [`config.lua`](hammerspoon.symlink/config.lua).
  - Manual window placement and sizing (with chaining to different sections of
    the screen as you repeat the keypresses).
    - Bound to `cmd+ctrl+j/k/l/h`.

* **Laptop "Docking/Undocking" Events**:

  - When docking my laptop (plugging in the single TB3 cable, aka using the laptop in
    desktop mode), it automatically switches:
    - switches [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements) profile to `dz60` (for my custom QMK-based 60% mechanical keyboard)
    - switches audio output to `Caldigit Thunderbolt 3 Audio`
    - switches audio input to `Samson GoMic`
    - switches off WiFi
  - It will reverse all of the above to the internal/built-in devices of my MacBook Pro when
    unplugging the single TB3 cable

- **[Hubitat Elevation](https://www.hubitat.com) Integration**:

  - Using a shell script I wrote in `bin/hubitat`, you can do basic control and querying of hubitat. This is useful because, based on certain automations in hammerspoon, I can control hubitat. For instance, turn on the office lamp when waking the computer (based on certain weather conditions, for example).

* **Other Things**:

  - I'm sure I missed some of the other things I've added or
    modified. The above documents the most notable and most used Hammerspoon automations.
  - Be sure to check out the main [config](hammerspoon.symlink/config.lua) to see what all is setup right now.

#### TODO

- [x] re-map Slack.app keybindings (https://github.com/STRML/init/blob/master/hammerspoon/init.lua#L306)
- [x] setup auto-away/status updates for Slack using the `hs.caffeinate` watcher
- [ ] thieve @evantravers pomodoro module (https://github.com/evantravers/hammerspoon/blob/master/pomodoro.lua)
