-- Uses hs.chooser to browse an objects attributes and children
--

-- TODO:
--      add flag so output is formal (uses method names) or informal (uses __call metamethod helpers)
--      option to copy final path into clipboard?
--      can we replace "obj" with something better?
--          if application object could use `hs.application(AXTitle)`
--          if windoe object could do same with hs.window and window title
--          if other, *then* use obj since we'll assume since they passed it in, they know how to get it...
--
--      what more before making this a spoon (after axuielement in core, of course)?

-- Example use:
--
--      -- Copy this file into your Hammerspoon config dir, usually ~/.hammerspoon. Then:
--      axbrowse = require("axbrowse")
--      axbrowse.browse(hs.axuielement.applicationElement(hs.application("Safari")))
--
-- When you select an end node, or escape out, you can return to the last place you were
-- at with `axbrowse.browse()`
--
-- axbrowse.browse(nil) will browse the frontmost application -- which will be
-- Hammerspoon if you're doing this from the console.
--
--      -- add the following to your `init.lua` file to make a hotkey to pull up the
--      -- browser in the frontmost application:
--
--       -- adjust require to where you install this relative to ~/.hammerspoon
--      local axbrowse = require("axbrowse")
--      local lastApp
--      hs.hotkey.bind({"cmd", "alt", "ctrl"}, "b", function()
--          local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
--          if currentApp == lastApp then
--              axbrowse.browse() -- try to continue from where we left off
--          else
--              lastApp = currentApp
--              axbrowse.browse(currentApp) -- new app, so start over
--          end
--      end)
--
-- As you select elements in the chooser window, a line will be printed to the console
-- which shows the path to the end node or action you finally select. These lines can
-- be copied into your own scripts and only the initial text "obj" needs to be
-- replaced with the actual element you started browsing from.
--

local ax = require("hs.axuielement")
local chooser = require("hs.chooser")
local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")
local timer = require("hs.timer")
local eventtap = require("hs.eventtap")
local application = require("hs.application")
local canvas = require("hs.canvas")
local window = require("hs.window")

-- Used for debugging
local cbinspect = function(...)
  local args = table.pack(...)
  if args.n == 1 and type(args[1]) == "table" then
    args = args[1]
  else
    args.n = nil -- supress the count from table.pack
  end

  local date = timer.secondsSinceEpoch()
  local timestamp =
    os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))

  print(timestamp .. ":: " .. inspect(args, { newline = " ", indent = "" }))
end

-- if Hamemrspoon goes away, the fact that this becomes invalid is kind of irrelevant because we disappear, too
local _hammerspoon = ax.applicationElement(hs.application.applicationsForBundleID(hs.processInfo.bundleID)[1])
local axmetatable = hs.getObjectMetatable("hs.axuielement")

local module = {}

local storage
local _chooser
local _canvas
local _errMsg

local buildChoicesForObject = function(obj)
  local aav = {}
  local textPrefix = ""
  local choices = {}

  local objIsTable = (type(obj) == "table")
  local objIsAXUIElement = (getmetatable(obj) == axmetatable)

  if #storage > 0 then table.insert(choices, { text = "<-- Go back" }) end

  table.insert(storage, {
    element = obj,
  })

  if objIsAXUIElement then aav = obj:allAttributeValues(true)     --         textPrefix = "Attribute: "
end

  if objIsTable then
    storage[#storage].element = storage[#storage - 1].element
    storage[#storage].attribute = storage[#storage - 1].tableAttribute or storage[#storage - 1].attribute
    storage[#storage].path = {}
    for i, v in ipairs(storage[#storage - 1].path or {}) do
      storage[#storage].path[i] = v
    end
    aav = obj
  end

  for k, v in fnutils.sortByKeys(aav) do
    local entry = {}
    if type(v) == "table" and v._code == -25212 then
      entry.text = textPrefix .. k .. " = nil"
      entry.subText = ""
      --             entry.subText  = "Value: nil"
      entry.cmdNoAdd = true
    elseif type(v) == "table" then
      entry.text = textPrefix .. k .. " = { ... }"
      if #v == 0 and next(v) then
        entry.subText = "key-value table"
        entry.text = entry.text .. "   -->"
      else
        if #v > 0 then
          entry.text = entry.text .. "   -->"
          entry.subText = (#v > 1) and (tostring(#v) .. " entries") or "1 entry"
        else
          entry.cmdNoAdd = true
          entry.subText = "0 entries"
        end
      end
      if not entry.cmdNoAdd then entry[(objIsTable and "index" or "attribute")] = k end
    elseif getmetatable(v) == axmetatable then
      if objIsTable then
        entry.text = tostring(k) .. ": " .. tostring(v.AXRole)
        entry.index = k
      else
        entry.text = textPrefix .. k
        entry.attribute = k
      end
      entry.text = entry.text .. "   -->"
      entry.subText = "Role: "
        .. tostring(v.AXRole)
        .. ", Subrole: "
        .. tostring(v.AXSubrole)
        .. ", Description: "
        .. tostring(v.AXValueDescription or v.AXDescription or v.AXRoleDescription)
    else
      entry.text = textPrefix .. k .. " = " .. inspect(v)
      entry.subText = ""
      --             entry.subText  = "Value: " .. inspect(v)
      entry.cmdNoAdd = true
    end
    if objIsAXUIElement and obj:isAttributeSettable(k) then
      entry.subText = entry.subText
        .. ((#entry.subText > 0) and ", s" or "S")
        .. "ettable (hold down ⌘ when selecting to show setter form)"
      entry.settable = true
    end

    if objIsTable then
      local quote = (type(k) == "number") and "" or "\""
      entry.cmdAddition = (type(k) == "number") and ("[" .. tostring(k) .. "]") or ("." .. k)
    else
      entry.cmdAddition = "." .. k
      if entry.settable then entry.altCmd = entry.cmdAddition .. " = ..." end
    end
    table.insert(choices, entry)
  end

  if objIsAXUIElement then
    local actions = obj:actionNames()
    if actions then
      table.sort(actions)
      for i, v in ipairs(actions) do
        table.insert(choices, {
          text = "Action: " .. v,
          subText = (obj:actionDescription(v) or "no description") .. ", hold down ⌘ when selecting to perform",
          action = v,
          cmdAddition = ":do" .. v .. "()",
          cmdNoAdd = true,
        })
      end
    end

    local pAttributes = obj:parameterizedAttributeNames()
    if pAttributes then
      table.sort(pAttributes)
      for i, v in ipairs(pAttributes) do
        table.insert(choices, {
          text = "Parameterized Attribute: " .. v,
          subText = "",
          cmdAddition = ":" .. v .. "WithParameter(...)",
          cmdNoAdd = true,
        })
      end
    end
  end

  return choices
end

local chooserCallback = function(item)
  if module.debug then
    cbinspect(item)
    cbinspect(storage)
  end

  if type(item) == "nil" then return end

  local obj
  local objDetails = storage[#storage]

  if item.text:match("^<--") then
    table.remove(storage) -- remove the one we displayed
    objDetails = table.remove(storage) -- remove the one we're now at because it will be recreated
    obj = objDetails.element
    if objDetails.attribute then obj = obj[objDetails.attribute] end
    if objDetails.path then
      table.remove(objDetails.path)
      for i, v in ipairs(objDetails.path) do
        obj = obj[v]
      end
    end
    storage._path = storage._path:match("^(.*)[%.%[]%w+%]?$")
  end

  if item.attribute then
    obj = objDetails.element[item.attribute]
    if type(obj) == "table" then objDetails.tableAttribute = item.attribute end
  end

  if item.index then
    table.insert(objDetails.path, item.index)
    obj = objDetails.element[objDetails.attribute]
    for i, v in ipairs(objDetails.path) do
      obj = obj[v]
    end
    local quote = (type(item.label) == "number") and "" or "\""
  end

  if item.settable and eventtap.checkKeyboardModifiers().cmd then
    obj = nil
    item.cmdAddition = item.altCmd
    item.cmdNoAdd = true
  end

  print((storage._path .. (item.cmdAddition or "")))
  if not item.cmdNoAdd then storage._path = storage._path .. (item.cmdAddition or "") end

  if obj then
    _chooser:choices(buildChoicesForObject(obj)):query(nil):selectedRow(1):show()
  else
    if item.action and eventtap.checkKeyboardModifiers().cmd then
      print(objDetails.element:performAction(item.action))
    end
  end
end

local showingChooser = function()
  -- it seems if the chooser is double triggered, it never calls the callback or hide for the initial one
  if _canvas then
    _canvas:delete()
    _canvas = nil
  end
  -- chooser window attribute doesn't exist until after it's showing, so we can't get the frame until
  -- after it's visible
  for i, v in ipairs(_hammerspoon) do
    if v.AXTitle == "Chooser" then
      -- because of window shadow for chooser, can't perfectly match up lines, so draw canvas slightly larger
      -- and make it look like the chooser is part of the canvas
      local chooserFrame = v.AXFrame
      _canvas = canvas
        .new({
          x = chooserFrame.x - 5,
          y = chooserFrame.y - 44,
          h = chooserFrame.h + 49,
          w = chooserFrame.w + 10,
        })
        :show()
        :level(canvas.windowLevels.mainMenu + 3)
        :orderBelow()
      _canvas[#_canvas + 1] = {
        type = "rectangle",
        action = "strokeAndFill",
        strokeColor = { list = "System", name = "controlBackgroundColor" },
        strokeWidth = 1.5,
        fillColor = { list = "System", name = "windowBackgroundColor" },
      }
      _canvas[#_canvas + 1] = {
        type = "text",
        frame = { x = 0, y = 0, h = 22, w = chooserFrame.w + 10 },
        text = storage._appElement.AXTitle,
        textColor = { list = "System", name = "textColor" },
        textSize = 16,
        textAlignment = "center",
      }
      _canvas[#_canvas + 1] = {
        type = "text",
        frame = { x = 5, y = 22, h = 22, w = chooserFrame.w },
        text = _errMsg or storage._path,
        textColor = { red = (_errMsg and 1 or 0), green = (_errMsg and 0 or 1) },
        textSize = 14,
        textLineBreak = "truncateHead",
      }
      _errMsg = nil
      return
    end
  end
  print("** unable to identify chooser window element")
  _canvas = nil -- just to be explicit
end

local hidingChooser = function()
  if _canvas then
    _canvas:delete()
    _canvas = nil
  end
end

_chooser = chooser.new(chooserCallback):searchSubText(true):showCallback(showingChooser):hideCallback(hidingChooser)
-- module._chooser = _chooser

module.debug = false

module.browse = function(...)
  local args = table.pack(...)
  if args.n > 0 then
    local obj = args[1]
    storage = { _path = "obj" }
    if obj then
      local appElement = obj
      while appElement.AXRole ~= "AXApplication" do
        appElement = appElement.AXParent
      end
      storage._appElement = appElement
      _chooser:choices(buildChoicesForObject(obj)):query(nil):selectedRow(1)
    end
  else
    if _chooser:isVisible() then -- called with no value but visible, so assume it's a toggle
      _chooser:cancel()
      return
    else -- called with no value -- make sure obj is still valid
      if storage and #storage > 0 then
        if not storage[#storage].element:isValid() then
          _errMsg = "** recently visited element no longer valid; resetting to application root"
          print(_errMsg)
          if not storage._appElement:isValid() then
            _errMsg = "** recently visited application no longer valid; resetting to frontmost application"
            print(_errMsg)

            storage = nil
            return module.browse()
          else
            return module.browse(storage._appElement)
          end
        end
      end
    end
  end

  if not storage or #storage == 0 then
    local currentApp = ax.applicationElement(application.frontmostApplication())
    storage = { _path = "obj", _appElement = currentApp }
    _chooser:choices(buildChoicesForObject(currentApp)):query(nil):selectedRow(1)
  end

  _chooser:show()
end

module.browseApplication = function(app)
  -- hs.application.find currently returns window objs as well and may not put apps first
  for i, v in ipairs(table.pack(application.find(app))) do
    if getmetatable(v) == hs.getObjectMetatable("hs.application") then return module.browse(v) end
  end
  error("requires string/number corresponding to an application as per hs.application.find", 2)
end

module.browseWindow = function(win)
  local obj = window.find(win)
  if obj then
    return module.browse(obj)
  else
    error("requires string/number corresponding to a window as per hs.window.find", 2)
  end
end

return module
