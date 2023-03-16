--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Pluggable launch bar
--
-- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Seal.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/Seal.spoon.zip)
--
-- Seal includes a number of plugins, which you can choose to load (see `:loadPlugins()` below):
--  * apps : Launch applications by name
--  * calc : Simple calculator
--  * rot13 : Apply ROT13 substitution cipher
--  * safari_bookmarks : Open Safari bookmarks (this is broken since at least High Sierra)
--  * screencapture : Lets you take screenshots in various ways
--  * urlformats : User defined URL formats to open
--  * useractions : User defined custom actions
--  * vpn : Connect and disconnect VPNs (currently supports Viscosity and macOS system preferences)A
---@class spoon.Seal
local M = {}
spoon.Seal = M

-- Binds hotkeys for Seal
--
-- Parameters:
--  * mapping - A table containing hotkey modifier/key details for the following (optional) items:
--   * show - This will cause Seal's UI to be shown
--   * toggle - This will cause Seal's UI to be shown or hidden depending on its current state
--
-- Returns:
--  * The Seal object
function M:bindHotkeys(mapping, ...) end

-- Loads a plugin from a given file
--
-- Parameters:
--  * plugin_name - the name of the plugin, without "seal_" at the beginning or ".lua" at the end
--  * file - the file where the plugin code is stored.
--
-- Returns:
--  * The Seal object if the plugin was successfully loaded, `nil` otherwise
--
-- Notes:
--  * You should normally use `Seal:loadPlugins()`. This method allows you to load plugins
--    from non-standard locations and is mostly a development interface.
--  * Some plugins may immediately begin doing background work (e.g. Spotlight searches)
function M:loadPluginFromFile(plugin_name, file, ...) end

-- Loads a list of Seal plugins
--
-- Parameters:
--  * plugins - A list containing the names of plugins to load
--
-- Returns:
--  * The Seal object
--
-- Notes:
--  * The plugins live inside the Seal.spoon directory
--  * The plugin names in the list, should not have `seal_` at the start, or `.lua` at the end
--  * Some plugins may immediately begin doing background work (e.g. Spotlight searches)
function M:loadPlugins(plugins, ...) end

-- List of directories where Seal will look for plugins. Defaults to `~/.hammerspoon/seal_plugins/` and the Seal Spoon directory.
M.plugin_search_paths = nil

-- Time between the last keystroke and the start of the recalculation of the choices to display, in seconds.
--
-- Notes:
--  * Defaults to 0.02s (20ms).
M.queryChangedTimerDuration = nil

-- Refresh the list of commands provided by all the currently loaded plugins.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The Seal object
--
-- Notes:
--  * Most Seal plugins expose a static list of commands (if any), which are registered at the time the plugin is loaded. This method is used for plugins which expose a dynamic or changing (e.g. depending on configuration) list of commands.
function M:refreshAllCommands() end

-- Refresh the list of commands provided by the given plugin.
--
-- Parameters:
--  * plugin_name - the name of the plugin. Should be the name as passed to `loadPlugins()` or `loadPluginFromFile`.
--
-- Returns:
--  * The Seal object
--
-- Notes:
--  * Most Seal plugins expose a static list of commands (if any), which are registered at the time the plugin is loaded. This method is used for plugins which expose a dynamic or changing (e.g. depending on configuration) list of commands.
function M:refreshCommandsForPlugin(plugin_name, ...) end

-- Shows the Seal UI
--
-- Parameters:
--  * query - An optional string to pre-populate the query box with
--
-- Returns:
--  * None
--
-- Notes:
--  * This may be useful if you wish to show Seal in response to something other than its hotkey
function M:show(query, ...) end

-- Starts Seal
--
-- Parameters:
--  * None
--
-- Returns:
--  * The Seal object
function M:start() end

-- Stops Seal
--
-- Parameters:
--  * None
--
-- Returns:
--  * The Seal object
--
-- Notes:
--  * Some Seal plugins will continue performing background work even after this call (e.g. Spotlight searches)
function M:stop() end

-- Shows or hides the Seal UI
--
-- Parameters:
--  * query - An optional string to pre-populate the query box with
--
-- Returns:
--  * None
function M:toggle(query, ...) end

