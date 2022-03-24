## [ Hammerspoon ](https://www.hammerspoon.org)⚭

### What even is this?

The simplest answer is that Hammerspoon is a Lua-based automation framework for
your macOS-based computer. It has a robust and [well-documented](http://www.hammerspoon.org/docs/) Lua layer on top
of the macOS core libraries and APIs.

### So, what does my [config](hammerspoon/.config/hammerspoon/config.lua) do (it's the primary setup for everything; and contains the trigger for many automations)?

- **Push-to-Talk (PTT)**: includes a handy menubar icon for current "talk" status. Bound to holding `cmd+opt`.

  - Toggle between push-to-talk (PTT) and push-to-mute (PTM) modes with `cmd+opt+p`

- **Spotify Controls**: simple keybindings to handle Play/Pause, Next, Previous.
  Bound to `hyper+shift+[`, `hyper+shift+]`, `hyper+shift+\`.

- **Computer Locking**: locks your computer with a set of key commands. Bound to
  `cmd+ctrl+shift+l`.

- **Accidental application quitting protection**: prevents accidental app quitting,
  makes you hit `cmd+q` twice.

- **Application Launching via "hyper" key (`F19`)** (for example):

  - Finder: `hyper+f`
  - Brave: `hyper+j`
  - Kitty: `hyper+k`
  - Slack: `hyper+s`
  - Spark: `hyper+e`
  - Zoom: `hyper+z`
  - Things: `hyper+t`
  - Dash: `hyper+d`
  - Drafts: `hyper+shift+d`
  - Messages: `hyper+m`
  - Spotify: `hyper+8`

- **App-specific customization via contexts**:

  - apps can define their own custom `context` file to execute any number of
    arbitrary things when that app is created, destroyed, focused or unfocused;
    for example, custom keybinding that override the app's defaults; or..

    - apps can toggle DND and Slack status modes
    - apps can auto-pause Spotify
    - apps can enable/disable QuitGuard™
    - apps can auto-hide after (n)-minute interval
    - apps can auto-quit after (n)-minute interval

- **Window Management**:

  - Automatic window placement, as presently configured in [`config.lua`](hammerspoon.symlink/config.lua).
  - Manual window placement and sizing (with chaining to different sections of
    the screen as you repeat the keypresses).
    - Bound to `cmd+ctrl+j/k/l/h`.
  - A 50/50% split screen, or 70/30% split screen feature via `hyper+v` (thanks
    [@evantravers!](https://github.com/evantravers/hammerspoon/blob/master/movewindows.lua#L72-L112))

- **Laptop "Docking/Undocking" Events**:

  - When docking my laptop (USB watcher on a pre-configured USB device), it automatically:
    - toggles [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements) profiles
    - switches audio output to pre-configured preferred output device
    - switches audio input to pre-configured preferred input device
    - toggles on/off WiFi

- **[Hubitat Elevation](https://www.hubitat.com) Integration**:

  - Using a shell script I wrote in `bin/hubitat`, you can do basic control and querying of hubitat. This is useful because, based on certain automations in hammerspoon, I can control hubitat. For instance, turn on the office lamp when waking the computer (based on certain weather conditions, for example).

- **Other Things**:

  - I'm sure I missed some of the other things I've added or
    modified. The above documents the most notable and most used Hammerspoon automations.
  - Be sure to check out the main [config](hammerspoon.symlink/config.lua) to see what all is setup right now.

#### TODO

- [ ] thieve @evantravers pomodoro module (https://github.com/evantravers/hammerspoon/blob/master/pomodoro.lua)
- [ ] use urlevents to enable/disable distraction URLS, especially when in a
      focus session via pomodoro

#### References

- [Learn Lua!](https://learnxinyminutes.com/docs/lua/)
- [Originator of my module layout](https://github.com/szymonkaliski/dotfiles/tree/master/Dotfiles/hammerspoon)
- [Example user of same module layout](https://github.com/AhmedAbdulrahman/dotfiles/blob/master/hammerspoon/init.lua)
- [Clipboard things](https://github.com/victorandree/dotfiles/blob/master/hammerspoon/.hammerspoon/common.lua)
- [More pomodoro](https://github.com/jacks808/hammerspoon-config/blob/master/pomodoor/pomodoor.lua)
- https://github.com/AdamWagner/stackline
- https://github.com/folke/dot/blob/master/hammerspoon/running.lua
- https://github.com/smithbm2316/dotfiles/tree/main/hammerspoon
