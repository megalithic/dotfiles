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

-- Default URL handler (Defaults to `"com.apple.Safari"`)
--
-- Notes:
-- Can be a string containing the Bundle ID of an application, or a function
-- that takes one argument, and which will be invoked with the URL to open.
M.default_handler = nil

-- Dispatch a URL to an application according to the defined `url_patterns`.
--
-- Parameters:
--  * scheme - A string containing the URL scheme (i.e. "http")
--  * host - A string containing the host requested (e.g. "www.hammerspoon.org")
--  * params - A table containing the key/value pairs of all the URL parameters
--  * fullURL - A string containing the full, original URL. This is the only parameter used in this implementation.
--  * senderPID - An integer containing the PID of the application that opened the URL, if available (otherwise -1)
--
-- Notes:
--  * The parameters (follow to the [httpCallback](http://www.hammerspoon.org/docs/hs.urlevent.html#httpCallback) specification)
function M:dispatchURL(scheme, host, params, fullUrl, senderPid, ...) end

-- Logger object used within the Spoon. Can be accessed to set the default log
-- level for the messages coming from the Spoon.
--
-- Notes:
-- Example: `spoon.URLDispatcher.logger.setLogLevel("debug")`
M.logger = nil

-- Internal variable containing a table where the pattern lists read from files are kept indexed by file name, and automatically updated.
M.pat_files = nil

-- Internal variable containing a table where the watchers for the pattern files are kept indexed by file name.
M.pat_watchers = nil

-- If true, URLDispatcher sets itself as system handler for http requests.
-- Defaults to `true`
M.set_system_handler = nil

-- Start dispatching URLs according to the rules
--
-- Parameters:
--  * None
function M:start() end

-- URL dispatch rules.
--
-- Notes:
--  A table containing a list of dispatch rules. Rules are evaluated in the
--  order they are declared. Each rule is a table with the following structure:
--  `{ url-patterns, app-bundle-ID-or-function, function, app-patterns }`
--  * `url-patterns` can be: (a) a single pattern as a string, (b) a table
--    containing a list of strings, or (c) a string containing the path of a
--    file from which the patterns will be read (if the string contains a valid
--    filename it's used as a file, otherwise as a pattern). In case (c), a
--    watcher will be set to automatically re-read the contents of the file
--    when it changes. If a relative path is given (not starting with a "/"),
--    then it is considered to be relative to the Hammerspoon configuration
--    directory.
--  * If `app-bundle-ID-or-function` is specified as a string, it is
--    interpreted as a macOS application ID, and that application will be used
--    to open matching URLs. If it is a function pointer, or not given but
--    "function" is provided, it is expected to be a function that accepts a
--    single argument, and it will be called with the URL.
--  * If `app-patterns` is given, it should be a string or a table containing a
--    pattern/list of patterns, and the rule will only be evaluated if the URL
--    was opened from an application whose name matches one of those patterns.
--  * Note that the patterns are [Lua patterns](https://www.lua.org/pil/20.2.html)
--    and not regular expressions.
--  * Defaults to an empty table, which has the effect of having all URLs
--    dispatched to the `default_handler`.
M.url_patterns = nil

-- URL redirection decoders. Default value: empty list
--
-- Notes:
-- List containing optional redirection decoders (other than the known Slack
-- decoder, which is enabled by `URLDispatcher.decode_slack_redir_urls` to
-- apply to URLs before dispatching them. Each list element must be a list
-- itself with a maximum of five elements:
--   * `decoder-name`: (String) a name to identify the decoder;
--   * `decoder-pattern-or-function`: (String or Function) if a string is
--     given, it is used as a [Lua pattern](https://www.lua.org/pil/20.2.html)
--     to match against the URL. If a function is given, it will be called with
--     arguments `scheme`, `host`, `params`, `fullUrl`, `senderPid` (the same
--     arguments as passed to
--     [hs.urlevent.httpCallback](https://www.hammerspoon.org/docs/hs.urlevent.html#httpCallback)),
--     and must return a string that contains the URL to be opened. The
--     returned value will be URL-decoded according to the value of `skip-decode-url` (below).
--   * `pattern-replacement`: (String) a replacement pattern to apply if a
--     match is found when a decoder pattern (previous argument) is provided.
--     If a decoder function is given, this argument is ignored.
--   * `skip-decode-url`: (Boolean, optional) whether to skip URL-decoding of the
--     resulting string (defaults to `false`, by default URLs are always decoded)
--   * `source-application`: (String or Table, optional): a pattern or list of
--     patterns to match against the name of the application from which the URL
--     was opened. If this parameter is present, the decoder will only be
--     applied when the application matches. Default is to apply the decoder
--     regardless of the application.
-- If given as strings, `decoder-pattern-or-function` and `pattern-replacement`
-- are passed as arguments to
-- [string.gsub](https://www.lua.org/manual/5.3/manual.html#pdf-string.gsub)
-- applied on the original URL.
M.url_redir_decoders = nil

