--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- Route URLs to different applications with pattern matching
--
-- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/URLDispatcher.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/URLDispatcher.spoon.zip)
--
-- Sets Hammerspoon as the default browser for HTTP/HTTPS links, and
-- dispatches them to different apps according to the patterns defined
-- in the config. If no pattern matches, `default_handler` is used.
---@class spoon.URLDispatcher
local M = {}
spoon.URLDispatcher = M

-- If true, handle Slack-redir URLs to apply the rule on the destination URL. Defaults to `true`
M.decode_slack_redir_urls = nil

-- Bundle ID for default URL handler. (Defaults to `"com.apple.Safari"`)
M.default_handler = nil

-- Dispatch a URL to an application according to the defined `url_patterns`.
--
-- Parameters:
--  * scheme - A string containing the URL scheme (i.e. "http")
--  * host - A string containing the host requested (e.g. "www.hammerspoon.org")
--  * params - A table containing the key/value pairs of all the URL parameters
--  * fullURL - A string containing the full, original URL. This is the only parameter used in this implementation.
--
-- Notes:
--  * The parameters (follow to the [httpCallback](http://www.hammerspoon.org/docs/hs.urlevent.html#httpCallback) specification)
function M:dispatchURL(scheme, host, params, fullUrl, ...) end

-- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
M.logger = nil

-- If true, URLDispatcher set itself as system handler for http requests. Defaults to `true`
M.set_system_handler = nil

-- Start dispatching URLs according to the rules
--
-- Parameters:
--  * None
function M:start() end

-- URL dispatch rules.
--
-- Notes:
--  * A table containing a list of dispatch rules. Each rule should be its own table in the format: `{ "url pattern", "application bundle ID", "function" }`, and they are evaluated in the order they are declared.
--  * Note that the patterns are [Lua patterns](https://www.lua.org/pil/20.2.html) and not regular expressions.
--  * Defaults to an empty table, which has the effect of having all URLs dispatched to the `default_handler`.
--  * If "application bundle ID" is specified, that application will be used to open matching URLs. If no "application bundle ID" is specified, but "function" is provided (and is a Lua function) it will be called with the URL.
M.url_patterns = nil

-- List containing optional additional redirection decoders (other
-- than the known Slack decoder, which is enabled by
-- `URLDispatcher.decode_slack_redir_urls` to apply to URLs before
-- dispatching them. Each list element must be a list itself with four
-- elements:
--   * String: a name to identify the decoder;
--   * String: a [Lua pattern](https://www.lua.org/pil/20.2.html) to match against the URL;
--   * String: a replacement pattern to apply if a match is found;
--   * (optional) Boolean: whether to skip URL-decoding of the resulting string (by default the results are always decoded);
--   * (optional) String or Table: a pattern or list of patterns to match against the name of the application from which the URL was opened. If this parameter is present, the decoder will only be applied when the application matches. Default is to apply the decoder regardless of the application.
-- The first two values are passed as arguments to
-- [string.gsub](https://www.lua.org/manual/5.3/manual.html#pdf-string.gsub)
-- applied on the original URL.  Default value: empty list
M.url_redir_decoders = nil

