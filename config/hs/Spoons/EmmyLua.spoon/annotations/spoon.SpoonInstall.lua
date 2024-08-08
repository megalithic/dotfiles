--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Install and manage Spoons and Spoon repositories
--
-- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/SpoonInstall.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/SpoonInstall.spoon.zip)
---@class spoon.SpoonInstall
local M = {}
spoon.SpoonInstall = M

-- Declaratively install, load and configure a Spoon
--
-- Parameters:
--  * name - the name of the Spoon to install (without the `.spoon` extension). If the Spoon is already installed, it will be loaded using `hs.loadSpoon()`. If it is not installed, it will be installed using `SpoonInstall:asyncInstallSpoonFromRepo()` and then loaded.
--  * arg - if provided, can be used to specify the configuration of the Spoon. The following keys are recognized (all are optional):
--    * repo - repository from where the Spoon should be installed if not present in the system, as defined in `SpoonInstall.repos`. Defaults to `"default"`.
--    * config - a table containing variables to be stored in the Spoon object to configure it. For example, `config = { answer = 42 }` will result in `spoon.<LoadedSpoon>.answer` being set to 42.
--    * hotkeys - a table containing hotkey bindings. If provided, will be passed as-is to the Spoon's `bindHotkeys()` method. The special string `"default"` can be given to use the Spoons `defaultHotkeys` variable, if it exists.
--    * fn - a function which will be called with the freshly-loaded Spoon object as its first argument.
--    * loglevel - if the Spoon has a variable called `logger`, its `setLogLevel()` method will be called with this value.
--    * start - if `true`, call the Spoon's `start()` method after configuring everything else.
--    * disable - if `true`, do nothing. Easier than commenting it out when you want to temporarily disable a spoon.
--
-- Returns:
--  * None
function M:andUse(name, arg, ...) end

-- Asynchronously install a Spoon from a registered repository
--
-- Parameters:
--  * name - Name of the Spoon to install.
--  * repo - Name of the repository to use. Defaults to `"default"`
--  * callback - if given, a function to call after the installation finishes (also if it fails). The function receives the following arguments:
--    * urlparts - Result of calling `hs.http.urlParts` on the URL of the Spoon zip file
--    * success - boolean indicating whether the installation was successful
--
-- Returns:
--  * `true` if the installation was correctly initiated (i.e. the repo and spoon name were correct), `false` otherwise.
function M:asyncInstallSpoonFromRepo(name, repo, callback, ...) end

-- Asynchronously download a Spoon zip file and install it.
--
-- Parameters:
--  * url - URL of the zip file to install.
--  * callback - if given, a function to call after the installation finishes (also if it fails). The function receives the following arguments:
--    * urlparts - Result of calling `hs.http.urlParts` on the URL of the Spoon zip file
--    * success - boolean indicating whether the installation was successful
--
-- Returns:
--  * `true` if the installation was correctly initiated (i.e. the URL is valid), `false` otherwise
function M:asyncInstallSpoonFromZipURL(url, callback, ...) end

-- Asynchronously fetch the information about the contents of all Spoon repositories registered in `SpoonInstall.repos`
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
--
-- Notes:
--  * For now, the repository data is not persisted, so you need to update it after every restart if you want to use any of the install functions.
function M:asyncUpdateAllRepos() end

-- Asynchronously fetch the information about the contents of a Spoon repository
--
-- Parameters:
--  * repo - name of the repository to update. Defaults to `"default"`.
--  * callback - if given, a function to be called after the update finishes (also if it fails). The function will receive the following arguments:
--    * repo - name of the repository
--    * success - boolean indicating whether the update succeeded
--
-- Returns:
--  * `true` if the update was correctly initiated (i.e. the repo name is valid), `nil` otherwise
--
-- Notes:
--  * For now, the repository data is not persisted, so you need to update it after every restart if you want to use any of the install functions.
function M:asyncUpdateRepo(repo, callback, ...) end

-- Synchronously install a Spoon from a registered repository
--
-- Parameters:
--  * name = Name of the Spoon to install.
--  * repo - Name of the repository to use. Defaults to `"default"`
--
-- Returns:
--  * `true` if the installation was successful, `nil` otherwise.
function M:installSpoonFromRepo(name, repo, ...) end

-- Synchronously download a Spoon zip file and install it.
--
-- Parameters:
--  * url - URL of the zip file to install.
--
-- Returns:
--  * `true` if the installation was successful, `nil` otherwise
function M:installSpoonFromZipURL(url, ...) end

-- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
M.logger = nil

-- Return a sorted list of registered Spoon repositories
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table containing a list of strings with the repository identifiers
function M:repolist() end

-- Table containing the list of available Spoon repositories. The key
-- of each entry is an identifier for the repository, and its value
-- is a table with the following entries:
--  * desc - Human-readable description for the repository
--  * branch - Active git branch for the Spoon files
--  * url - Base URL for the repository. For now the repository is assumed to be hosted in GitHub, and the URL should be the main base URL of the repository. Repository metadata needs to be stored under `docs/docs.json`, and the Spoon zip files need to be stored under `Spoons/`.
--
-- Default value:
-- ```
-- {
--    default = {
--       url = "https://github.com/Hammerspoon/Spoons",
--       desc = "Main Hammerspoon Spoon repository",
--       branch = "master",
--    }
-- }
-- ```
M.repos = nil

-- Search repositories for a pattern
--
-- Parameters:
--  * pat - Lua pattern that will be matched against the name and description of each spoon in the registered repositories. All text is converted to lowercase before searching it, so you can use all-lowercase in your pattern.
--
-- Returns:
--  * Table containing a list of matching entries. Each entry is a table with the following keys:
--    * name - Spoon name
--    * desc - description of the spoon
--    * repo - identifier in the repository where the match was found
function M:search(pat, ...) end

-- Synchronously fetch the information about the contents of all Spoon repositories registered in `SpoonInstall.repos`
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
--
-- Notes:
--  * This is a synchronous call, which means Hammerspoon will be blocked until it finishes.
--  * For now, the repository data is not persisted, so you need to update it after every restart if you want to use any of the install functions.
function M:updateAllRepos() end

-- Synchronously fetch the information about the contents of a Spoon repository
--
-- Parameters:
--  * repo - name of the repository to update. Defaults to `"default"`.
--
-- Returns:
--  * `true` if the update was successful, `nil` otherwise
--
-- Notes:
--  * This is a synchronous call, which means Hammerspoon will be blocked until it finishes. For use in your configuration files, it's advisable to use `SpoonInstall.asyncUpdateRepo()` instead.
--  * For now, the repository data is not persisted, so you need to update it after every restart if you want to use any of the install functions.
function M:updateRepo(repo, ...) end

-- If `true`, `andUse()` will update repos and install packages synchronously. Defaults to `false`.
--
-- Keep in mind that if you set this to `true`, Hammerspoon will
-- block until all missing Spoons are installed, but the notifications
-- will happen at a more "human readable" rate.
M.use_syncinstall = nil

