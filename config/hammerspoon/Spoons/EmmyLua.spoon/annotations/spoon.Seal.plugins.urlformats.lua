--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- A plugin to quickly open URLs containing a search/query term
-- This plugin is invoked with the `uf` keyword and requires some configuration, see `:providersTable()`
--
-- The way this works is by defining a set of providers, each of which contains a URL with a `%s` somewhere insert it.
-- When the user types `uf` in Seal, followed by some more characters, those characters will be inserted into the string at the point where the `%s` is.
--
-- By way of an example, you could define a provider with a url like `http://bugs.mycorp.com/showBug?id=%s`, and just need to type `uf 123456` in Seal to get a quick shortcut to open the full URL.
---@class spoon.Seal.plugins.urlformats
local M = {}
spoon.Seal.plugins.urlformats = M

-- Gets or sets the current providers table
--
-- Parameters:
--  * aTable - An optional table of providers, which must contain the following keys:
--    * name - A string naming the provider, which will be shown in the Seal results
--    * url - A string containing the URL to insert the user's query into. This should contain one and only one `%s`
--
-- Returns:
--  * Either a table of current providers, if no parameter was passed, or nothing if a parmameter was passed.
--
-- Notes:
--  * An example table might look like:
-- ```lua
-- {
--   rhbz = { name = "Red Hat Bugzilla", url = "https://bugzilla.redhat.com/show_bug.cgi?id=%s", },
--   lp = { name = "Launchpad Bug", url = "https://launchpad.net/bugs/%s", },
-- }
-- ```
function M:providersTable(aTable, ...) end

