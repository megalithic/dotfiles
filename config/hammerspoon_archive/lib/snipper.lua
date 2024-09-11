--[[
    From @maxandersen's gist here: https://gist.github.com/maxandersen/d09ebef333b0c7b7f947420e2a7bbbf5
    === HammerText ===
    Based on: https://github.com/Hammerspoon/hammerspoon/issues/1042
    How to "install":
    - Simply copy and paste this code in your "init.lua".
    How to use:
      - Add this init.lua to ~/.hammerspoon/Spoons/HammerText.spoon
      - Add your hotstrings (abbreviations that get expanded) to the "keywords" list following the example format.
      ht = hs.loadSpoon("HammerText")
      ht.keywords ={
         nname = "Max Rydahl Andersen",
         xdate = function() return os.date("%B %d, %Y") end,
      }
      ht:start()
    Features:
    - Text expansion starts automatically in your init.lua config.
    - Hotstring expands immediately.
    - Word buffer is cleared after pressing one of the "navigational" keys.
      PS: The default keys should give a good enough workflow so I didn't bother including other keys.
          If you'd like to clear the buffer with more keys simply add them to the "navigational keys" conditional.
    Limitations:
    - Can't expand hotstring if it's immediately typed after an expansion. Meaning that typing "..name..name" will result in "My name..name".
      This is intentional since the hotstring could be a part of the expanded string and this could cause a loop.
      In that case you have to type one of the "buffer-clearing" keys that are included in the "navigational keys" conditional (which is very often the case).
--]]

--- HT: https://github.com/cweagans/dotfiles/commit/84da84d672bb2158b95fa28e5dd840dd21d3bb1c
local obj = {}
local utf8 = require("utf8")
local emoji = require("utils.emoji")

obj.__index = obj
obj.name = "snipper"
obj.debug = _G.debug_enabled
obj.watcher = nil
obj.snippets = {}

local expander = function(snippets)
  snippets = U.table_merge(obj.snippets, snippets or {})

  local word = ""
  local keyMap = require("hs.keycodes").map
  local keyWatcher
  local DEBUG = false --if DEBUG then obj.debug

  -- create an "event listener" function that will run whenever the event happens
  keyWatcher = hs.eventtap
    .new({ hs.eventtap.event.types.keyDown }, function(ev)
      local keyCode = ev:getKeyCode()
      local char = ev:getCharacters()
      if char == nil then char = "" end

      -- if keyCode == 0 and char == nil then
      --   warn("keyCode is 0 or char is nil: ", { keyCode, char })
      --
      --   word = ""
      --   return false
      -- end

      -- if "delete" key is pressed
      if keyCode == keyMap["delete"] then
        if #word > 0 then
          -- remove the last char from a string with support to utf8 characters
          local t = {}
          for _, chars in utf8.codes(word) do
            table.insert(t, chars)
          end
          table.remove(t, #t)
          word = utf8.char(table.unpack(t))
          if DEBUG then print("Word after deleting:", word) end
        end
        return false -- pass the "delete" keystroke on to the application
      end

      -- append char to "word" buffer
      word = word .. char
      if DEBUG then print("Word after appending:", word) end

      if
        keyCode == keyMap["alt"]
        or keyCode == keyMap["cmd"]
        or keyCode == keyMap["escape"]
        or keyCode == keyMap["F19"]
        or keyCode == keyMap["up"]
        or keyCode == keyMap["down"]
        or keyCode == keyMap["left"]
        or keyCode == keyMap["right"]
        or keyCode == keyMap["return"]
        or keyCode == keyMap["space"]
      then
        word = "" -- clear the buffer
      end
      -- elseif keyCode == keyMap["return"] or keyCode == keyMap["space"] then
      -- word = string.gsub(word, "^%s*(.-)%s*$", "%1")

      print("Word to check if hotstring:", word)

      -- finally, if "word" is a hotstring
      if snippets[word] then
        print("Snippet for hotstring:", I(snippets[word]))
        for i = 1, utf8.len(word), 1 do
          hs.eventtap.keyStroke({}, "delete", 0)
        end -- delete the abbreviation

        if type(snippets[word]) == "function" then
          hs.eventtap.keyStrokes(snippets[word]())
        else
          hs.eventtap.keyStrokes(snippets[word]) -- expand the word
        end

        word = "" -- clear the buffer
      end

      -- end

      return false -- pass the event on to the application
    end)
    :start() -- start the eventtap

  -- return keyWatcher to assign this functionality to the "expander" variable to prevent garbage collection
  return keyWatcher
end

local function expandSnippet(snippets, word)
  -- finally, if "word" is a hotstring
  dbg("word to parse: ", word)

  local output = snippets[word]
  if not output then
    output = hs.fnutils.find(snippets, function(snippet)
      dbg(snippet)
      -- dbg("snippet: %s, word: %s, match found? %s", snippet, word, string.find(word, snippet))
      return false
      -- return string.find(word, snippet) ~= nil
    end)
  end

  dbg("snippet to write: ", output)

  if type(output) == "function" then -- expand if function
    local ok, o = pcall(output)
    if not ok then
      error("~~ expansion for '" .. word .. "' gave an error of " .. o)
      -- could also set o to nil here so that the expansion doesn't occur below, but I think
      -- seeing the error as the replacement will be a little more obvious that a print to the
      -- console which I may or may not have open at the time...
      -- maybe show an alert with hs.alert instead?
    end

    output = o
  end

  if output then
    -- for i = 1, utf8.len(word), 1 do
    --   hs.eventtap.keyStroke({}, "delete", 0)
    -- end -- delete the abbreviation

    dbg("expanding: ", output)
    dbg("word: ", word)

    hs.eventtap.keyStrokes(output) -- expand the word
    word = "" -- clear the buffer
  end

  return word
end

local function snipper(snippets)
  snippets = U.table_merge(obj.snippets, snippets or {})
  info(I(snippets))

  local word = ""
  local keyMap = require("hs.keycodes").map
  local keyWatcher

  -- create an "event listener" function that will run whenever the event happens
  keyWatcher = hs.eventtap
    .new({ hs.eventtap.event.types.keyDown }, function(ev)
      local keyCode = ev:getKeyCode()
      local char = ev:getCharacters()
      dbg("keyCode/char: ", { keyCode, char })

      if keyCode == 0 and char == nil then
        warn("keyCode is 0 or char is nil: ", { keyCode, char })

        word = ""
        return false
      end

      -- if "delete" key is pressed
      if keyCode == keyMap["delete"] then
        if #word > 0 then
          -- remove the last char from a string with support to utf8 characters
          local t = {}
          for _, chars in utf8.codes(word) do
            table.insert(t, chars)
          end
          table.remove(t, #t)
          word = utf8.char(table.unpack(t))
          -- dbg("Word after deleting:", word)
        end

        return false -- pass the "delete" keystroke on to the application
      end
      -- append char to "word" buffer
      -- dbg("Word before appending:", I(word))
      -- dbg("Char before appending:", I(char))
      word = word .. char
      -- dbg("Word after appending:", word)
      -- if one of these "navigational" keys is pressed
      if
        -- keyCode == keyMap["return"]
        -- or keyCode == keyMap["space"]
        keyCode == keyMap["ctrl"]
        or keyCode == keyMap["alt"]
        or keyCode == keyMap["cmd"]
        or keyCode == keyMap["escape"]
        or keyCode == keyMap["F19"]
        or keyCode == keyMap["up"]
        or keyCode == keyMap["down"]
        or keyCode == keyMap["left"]
        or keyCode == keyMap["right"]
        -- or keyCode == "\xEF\x9C\x96" -- (F19)
        -- or keyCode == "\x1B" -- (F19)
      then
        dbg("clearing word for a matched keymap.")
        word = "" -- clear the buffer
      end

      -- dbg("Word to check if hotstring:", word)

      if keyCode == keyMap["return"] or keyCode == keyMap["space"] then
        dbg(
          string.format(
            "keyCode is return (%s? %s) or space (%s? %s)",
            keyMap["return"],
            keyCode == keyMap["return"],
            keyMap["space"],
            keyCode == keyMap["space"]
          )
        )
        word = expandSnippet(snippets, word)
      end

      -- NOTE: trying expanding on space or return instead
      -- word = expandSnippet(output, word)

      return false -- pass the event on to the application
    end)
    :start() -- start the eventtap
  -- return keyWatcher to assign this functionality to the "expander" variable to prevent garbage collection
  return keyWatcher
end

local function buildTrie(snippets)
  local trie = {
    expandFn = nil,
    children = {},
  }

  for shortcode, snippet in pairs(snippets) do
    local currentElement = trie

    -- Loop through each character in the snippet keyword and insert a tree
    -- of nodes into the trie.
    for i = 1, #shortcode do
      local char = shortcode:sub(i, i)

      currentElement.children[char] = currentElement.children[char]
        or {
          expandFn = nil,
          children = {},
        }

      currentElement = currentElement.children[char]

      -- If we're on the last character, save off the snippet function
      -- to the node as well.
      local isLastChar = i == #shortcode

      if isLastChar then
        if type(snippet) == "function" then
          -- If the snippet is a function, just save it off to be called
          -- later.
          currentElement.expandFn = snippet
        else
          -- If the snippet is a static string, convert it to a function so that
          -- everything is uniformly a function.
          currentElement.expandFn = function() return snippet end
        end
      end
    end
  end

  return trie
end

local shiftedKeymap = {
  ["1"] = "!",
  ["2"] = "@",
  ["3"] = "#",
  ["4"] = "$",
  ["5"] = "%",
  ["6"] = "^",
  ["7"] = "&",
  ["8"] = "*",
  ["9"] = "(",
  ["0"] = ")",
  ["`"] = "~",
  ["-"] = "_",
  ["="] = "+",
  ["["] = "{",
  ["]"] = "}",
  ["\\"] = "|",
  ["/"] = "?",
  [","] = "<",
  ["."] = ">",
  ["'"] = "\"",
  [";"] = ":",
}

local unshiftedKeymap = {
  ["!"] = "1",
  ["@"] = "2",
  ["#"] = "3",
  ["$"] = "4",
  ["%"] = "5",
  ["^"] = "6",
  ["&"] = "7",
  ["*"] = "8",
  ["("] = "9",
  [")"] = "0",
  ["~"] = "`",
  ["_"] = "-",
  ["+"] = "=",
  ["{"] = "[",
  ["}"] = "]",
  ["|"] = "\\",
  ["?"] = "/",
  ["<"] = ",",
  [">"] = ".",
  ["\""] = "'",
  [":"] = ";",
}

local function getKeyCode(s)
  local n
  if type(s) == "number" then
    n = s
  elseif type(s) ~= "string" then
    error("key must be a string or a number", 3)
  elseif s:sub(1, 1) == "#" then
    n = tonumber(s:sub(2))
  else
    n = hs.keycodes.map[string.lower(s)]
  end
  if not n then
    error(
      "Invalid key: "
        .. s
        .. " - this may mean that the key requested does not exist in your keymap (particularly if you switch keyboard layouts frequently)",
      3
    )
  end

  return n
end

-- Returns a table with a key down and key up event for a given (mods, key)
-- key press.
local function keySequence(mods, key)
  return {
    hs.eventtap.event.newKeyEvent(mods, key, true),
    hs.eventtap.event.newKeyEvent(mods, key, false),
  }
end

function obj:init(opts)
  opts = opts or {}

  return self
end

function obj:start(opts)
  local snippets = U.table_merge(obj.snippets, opts or {})
  -- expander(snippets)
  -- snipper(snippets)

  local snippetTrie = buildTrie(snippets)
  local numPresses = 0
  local currentTrieNode = snippetTrie

  obj.snippetWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local keyPressed = hs.keycodes.map[event:getKeyCode()]

    if event:getFlags():containExactly({ "shift" }) then
      -- Convert the keycode to the shifted version of the key,
      -- e.g. "=" turns into "+", etc.
      keyPressed = shiftedKeymap[keyPressed] or keyPressed
    end

    local shouldFireSnippet = keyPressed == "return" or keyPressed == "space"

    local reset = function()
      currentTrieNode = snippetTrie
      numPresses = 0
    end

    if currentTrieNode.expandFn then
      if shouldFireSnippet then
        local keyEventsToPost = {}

        -- Delete backwards however many times a key has been typed, to remove
        -- the snippet "+keyword"
        for i = 1, numPresses do
          keyEventsToPost = hs.fnutils.concat(keyEventsToPost, keySequence({}, "delete"))
        end

        -- Call the snippet's function to get the snippet expansion.
        local textToWrite = currentTrieNode.expandFn()

        dbg("snippet to write: ", textToWrite)

        if emoji.has_emoji(textToWrite) then
          -- local converted = string.format("%#x", utf8.codepoint(textToWrite)):gsub("0x", "")
          -- local char = emoji.stringify_codepoints(emoji.parse_codepoints(textToWrite))
          -- dbg(char)
          -- keyEventsToPost = hs.fnutils.concat(keyEventsToPost, keySequence({}, char))
          dbg("utf8.codepoint", string.format("\\u%02x", utf8.codepoint(textToWrite)))
          --
          -- print("printing the converted and formatted: " .. string.format("\\u{%s}", converted))
          -- -- hs.pasteboard.writeObjects(textToWrite, "html")
          -- -- \u{1F308}
          -- dbg("emoji to write: ", textToWrite)
          -- -- hs.eventtap.keyStrokes(hs.utf8.codepointToUTF8(textToWrite))
          -- dbg("codepoints", emoji.codepoints(textToWrite))
          -- dbg("parse_codepoints", emoji.parse_codepoints(textToWrite))
          -- dbg(
          --   "longform imap",
          --   hs.fnutils.imap(hs.fnutils.split(textToWrite, "-"), function(s) return tonumber(s, 16) end)
          -- )
          -- dbg("codepointToUTF8 with unpack", hs.utf8.codepointToUTF8(table.unpack(textToWrite)))
          -- dbg("codepointToUTF8 no unpack", hs.utf8.codepointToUTF8(textToWrite))
          -- -- hs.eventtap.keyStrokes(hs.utf8.codepointToUTF8(table.unpack(textToWrite)))
          -- dbg("asciiOnly: ", hs.utf8.asciiOnly(textToWrite))
          -- hs.eventtap.keyStrokes(hs.utf8.asciiOnly(textToWrite)) -- string.format("\\u{%s}", converted))
          -- hs.pasteboard.getContents("html")

          hs.eventtap.keyStrokes(hs.execute(string.format([[echo "%s"]], textToWrite)))
        else
          for i = 1, textToWrite:len() do
            local char = textToWrite:sub(i, i)
            local flags = {}

            -- If you encounter a shifted character, like "*", you have to convert
            -- it back to its modifiers + keycode form.
            --
            -- Example:
            --   If char == "*"
            --   Send `shift + 8` instead.
            if unshiftedKeymap[char] then
              flags = { "shift" }
              char = unshiftedKeymap[char]
            end

            keyEventsToPost = hs.fnutils.concat(keyEventsToPost, keySequence(flags, char))
          end
        end

        -- Send along the keypress that activated the snippet (either space or
        -- return).
        -- hs.eventtap.keyStroke(event:getFlags(), keyPressed, 0)
        keyEventsToPost = hs.fnutils.concat(keyEventsToPost, keySequence(event:getFlags(), event:getKeyCode()))

        -- Reset our pointers back to the beginning to get ready for the next
        -- snippet.
        reset()

        -- Don't pass thru the original keypress, and return our replacement key
        -- events instead.
        return true, keyEventsToPost
      else
        reset()
        return false
      end
    end

    if currentTrieNode.children[keyPressed] then
      currentTrieNode = currentTrieNode.children[keyPressed]
      numPresses = numPresses + 1
    else
      reset()
    end

    return false
  end)

  obj.snippetWatcher:start()

  return self
end

function obj:stop(opts)
  opts = opts or {}

  obj.snippetWatcher:stop()
  obj.snippetWatcher = nil
  return self
end

return obj
