--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Allow accessing user-defined bookmarks and arbitrary actions from Seal.
-- 
---@class spoon.Seal.plugins.useractions
local M = {}
spoon.Seal.plugins.useractions = M

-- 
-- Notes:
--  * A table containing the definitions of static user-defined actions. Each entry is indexed by the name of the entry as it will be shown in the chooser. Its value is a table which can have the following keys (one of `fn` or `url` is required. If both are provided, `url` is ignored):
--   * fn - A function which will be called when the entry is selected. The function receives no arguments.
--   * url - A URL which will be opened when the entry is selected. Can also be non-HTTP URLs, such as `mailto:` or other app-specific URLs.
--   * description - (optional) A string or `hs.styledtext` object that will be shown underneath the main text of the choice.
--   * icon - (optional) An `hs.image` object that will be shown next to the entry in the chooser. If not provided, `Seal.plugins.useractions.default_icon` is used. For `url` bookmarks, it can be set to `"favicon"` to fetch and use the website's favicon.
--   * keyword - (optional) A command by which this action will be invoked, effectively turning it into a Seal command. Any arguments passed to the command will be handled as follows:
--     * For `fn` actions, passed as an argument to the function
--     * For `url` actions, substituted into the URL, taking the place of any occurrences of `${query}`.
--   * hotkey - (optional) A hotkey specification in the form `{ modifiers, key }` by which this action can be invoked.
--  * Example configuration:
-- ```
-- spoon.Seal:loadPlugins({"useractions"})
-- spoon.Seal.plugins.useractions.actions =
--    {
--       ["Hammerspoon docs webpage"] = {
--          url = "http://hammerspoon.org/docs/",
--          icon = hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon),
--          description = "Open Hammerspoon documentation",
--          hotkey = { hyper, "h" },
--       },
--       ["Leave corpnet"] = {
--          fn = function()
--             spoon.WiFiTransitions:processTransition('foo', 'corpnet01')
--          end,
--       },
--       ["Arrive in corpnet"] = {
--          fn = function()
--             spoon.WiFiTransitions:processTransition('corpnet01', 'foo')
--          end,
--       },
--       ["Translate using Leo"] = {
--          url = "http://dict.leo.org/ende/index_de.html#/search=${query}",
--          icon = 'favicon',
--          keyword = "leo",
--       },
--       ["Tell me something"] = {
--          keyword = "tellme",
--          fn = function(str) hs.alert.show(str) end,
--       }
-- ```
M.actions = nil

-- 
-- If `true`, attempt to obtain the favicon for URLs added through the `add` command, and use it in the chooser. Defaults to `true`
M.get_favicon = nil

