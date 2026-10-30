-- Regression tests for animator timer ownership and callback lifetime.
-- Run from config/hammerspoon: mise exec -- lua tests/animator.test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local passes, failures = 0, 0
local function check(value, message)
  if value then
    passes = passes + 1
  else
    failures = failures + 1
    print("FAIL: " .. message)
  end
end
local function equal(actual, expected, message)
  check(actual == expected, ("%s (got %s, want %s)"):format(message, tostring(actual), tostring(expected)))
end

-- This deliberately models the native split: callback refs live in a strong
-- registry, while native timer state never points back at the Lua userdata.
local function fakeHs()
  local clock, states, callbacks, nextId = 0, {}, {}, 0
  local timerStates = setmetatable({}, { __mode = "k" })
  local hs = { timer = {} }
  local timerMethods = {}
  local timerMeta = {
    __index = timerMethods,
    __gc = function(timer)
      local state = timerStates[timer]
      if state then
        state.running = false
        callbacks[state.id] = nil
        timerStates[timer] = nil
      end
    end,
  }
  function timerMethods:start()
    timerStates[self].running = true
    return self
  end
  function timerMethods:stop()
    timerStates[self].running = false
    return self
  end
  function timerMethods:running() return timerStates[self].running end
  local function makeTimer(state)
    local timer = setmetatable({}, timerMeta)
    timerStates[timer] = state
    return timer
  end
  local function install(interval, fn, mode)
    nextId = nextId + 1
    local state = { id = nextId, at = clock + interval, interval = interval, mode = mode, running = true, done = false }
    states[#states + 1] = state
    callbacks[state.id] = fn
    return makeTimer(state), state
  end
  function hs.timer.new(interval, fn) return install(interval, fn, "new") end
  function hs.timer.doEvery(interval, fn) return install(interval, fn, "every") end
  function hs.timer.doUntil(predicate, action, interval)
    local stopWatch
    stopWatch = hs.timer
      .new(interval, function()
        if not predicate() then
          action(stopWatch)
        else
          stopWatch:stop()
        end
      end)
      :start()
    return stopWatch
  end
  function hs._tick()
    local fired = true
    while fired do
      fired = false
      for _, state in ipairs(states) do
        if state.running and state.at <= clock then
          fired = true
          if state.mode == "every" or state.mode == "new" or state.mode == "until" then
            state.at = state.at + state.interval
          end
          local callback = callbacks[state.id]
          if callback then callback() end
        end
      end
    end
  end
  function hs.advance(seconds)
    clock = clock + seconds
    hs._tick()
  end
  function hs.callbackCount()
    local n = 0
    for _ in pairs(callbacks) do
      n = n + 1
    end
    return n
  end
  return hs
end

local sourceText
if arg and arg[1] then
  local file = assert(io.open(arg[1], "r"))
  sourceText = file:read("*a")
  file:close()
end
local function loadAnimator()
  if sourceText then
    local chunk, err = load(sourceText, arg[1])
    assert(chunk, err)
    return chunk()
  end
  return require("lib.hud.animator")
end
local function fresh()
  package.loaded["lib.hud.animator"] = nil
  _G.hs = fakeHs()
  return loadAnimator(), hs
end
local function gc()
  collectgarbage("collect")
  collectgarbage("collect")
end
local function weak(value) return setmetatable({ value = value }, { __mode = "v" }) end
local function run(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("ok: " .. name)
  else
    failures = failures + 1
    print("FAIL: " .. name .. ": " .. tostring(err))
  end
  _G.hs = nil
  package.loaded["lib.hud.animator"] = nil
  gc()
end
local function canvas(payload)
  return {
    payload = payload,
    topLeft = function(self, p)
      if p then self.pos = p end
      return self.pos or { x = 0, y = 0 }
    end,
    alpha = function(self, p)
      self.a = p
      return self.a
    end,
    show = function() end,
    hide = function() end,
    frame = function() return { x = 0, y = 0, w = 10, h = 10 } end,
    delete = function(self) self.deleted = true end,
  }
end

run("normal completion releases captured payload and completes exactly once", function()
  local a, h = fresh()
  local payload, complete, last = {}, 0, 0
  local ref = weak(payload)
  local captured = payload
  local timer = a.animate(50, function(progress)
    last = progress
    local _ = captured
  end, {
    easing = a.linear,
    onComplete = function()
      complete = complete + 1
      local _ = captured
    end,
  })
  payload = nil
  for _ = 1, 5 do
    h.advance(1 / a.FPS)
  end
  h.advance(1 / a.FPS)
  equal(complete, 1, "completion count")
  equal(last, 1, "final progress")
  equal(h.callbackCount(), 1, "retained native callback ref")
  captured = nil
  timer = nil
  gc()
  equal(h.callbackCount(), 0, "completed userdata gc releases callback")
  check(ref.value == nil, "payload collectable after completion")
end)

run("cancellation before first frame releases payload and suppresses completion", function()
  local a, h = fresh()
  local payload, complete = {}, 0
  local ref = weak(payload)
  local captured = payload
  local timer = a.animate(
    100,
    function() local _ = captured end,
    { easing = a.linear, onComplete = function() complete = complete + 1 end }
  )
  a.stop(timer)
  a.stop(timer)
  payload = nil
  h.advance(1)
  timer = nil
  captured = nil
  gc()
  equal(complete, 0, "cancelled completion")
  equal(h.callbackCount(), 0, "cancelled callback refs")
  check(ref.value == nil, "cancelled payload collectable")
end)

run("mid-animation cancellation releases canvas and payload", function()
  local a, h = fresh()
  local payload, complete = {}, 0
  local ref = weak(payload)
  local captured = payload
  local c = canvas(captured)
  local cref = weak(c)
  local timer = a.fadeIn(c, { duration = 100, onComplete = function() complete = complete + 1 end })
  h.advance(1 / a.FPS)
  a.stop(timer)
  payload, c, timer, captured = nil, nil, nil, nil
  gc()
  equal(complete, 0, "mid-animation completion")
  check(ref.value == nil and cref.value == nil, "mid-animation captures collectable")
end)

run("discarded return keeps native callback alive until completion", function()
  local a, h = fresh()
  local complete, ref
  local function start()
    local payload = {}
    ref = weak(payload)
    local captured = { value = payload }
    a.animate(50, function()
      if not captured.value then error("payload lost") end
    end, { easing = a.linear, onComplete = function() complete = (complete or 0) + 1 end })
  end
  start()
  gc()
  check(h.callbackCount() == 1, "active native callback retained")
  for _ = 1, 7 do
    h.advance(1 / a.FPS)
  end
  equal(complete, 1, "discarded timer completes")
  gc()
  equal(h.callbackCount(), 0, "discarded callback released")
  check(ref.value == nil, "discarded payload eventually collectable")
end)

run("retained completed timer does not retain callback payload", function()
  local a, h = fresh()
  local complete, ref, timer
  local function start()
    local payload = {}
    ref = weak(payload)
    local captured = payload
    timer = a.animate(50, function() assert(captured) end, {
      easing = function(progress)
        assert(captured)
        return progress
      end,
      onComplete = function()
        assert(captured)
        complete = (complete or 0) + 1
      end,
    })
  end
  start()
  for _ = 1, 7 do
    h.advance(1 / a.FPS)
  end
  gc()
  equal(complete, 1, "retained timer completion")
  equal(h.callbackCount(), 1, "retained completed callback ref")
  check(ref.value == nil, "retained timer releases payload")
  check(timer ~= nil, "timer remains externally usable")
  timer = nil
  gc()
  equal(h.callbackCount(), 0, "userdata gc releases callback ref")
end)

run("retained cancelled timer releases every callback capture", function()
  local a, h = fresh()
  local ref, timer
  local function start()
    local captured = {}
    ref = weak(captured)
    timer = a.animate(100, function() assert(captured) end, {
      easing = function(progress)
        assert(captured)
        return progress
      end,
      onComplete = function()
        assert(captured)
        error("cancelled completion ran")
      end,
    })
  end
  start()
  a.stop(timer)
  gc()
  equal(h.callbackCount(), 1, "retained cancelled callback ref")
  check(ref.value == nil, "retained cancelled timer releases all captures")
  timer = nil
  gc()
  equal(h.callbackCount(), 0, "cancelled userdata gc releases callback ref")
end)

run("onFrame error releases native callback and rethrows", function()
  local a, h = fresh()
  local payload, ref, timer = {}, nil, nil
  ref = weak(payload)
  local captured = payload
  timer = a.animate(100, function()
    local _ = captured
    error("frame boom")
  end, { easing = a.linear })
  local ok = pcall(function() h.advance(1 / a.FPS) end)
  payload, timer, captured = nil, nil, nil
  gc()
  check(not ok, "frame error propagates")
  equal(h.callbackCount(), 0, "frame error callback release")
  check(ref.value == nil, "frame error payload collectable")
end)

run("easing and completion errors release native callback and rethrow", function()
  local a, h = fresh()
  local payload, ref = {}, nil
  ref = weak(payload)
  local captured = payload
  a.animate(20, function() local _ = captured end, { easing = function() error("easing boom") end })
  local ok = pcall(function() h.advance(1 / a.FPS) end)
  payload, captured = nil, nil
  gc()
  check(not ok and h.callbackCount() == 0 and ref.value == nil, "easing error cleanup")
  local complete = {}
  local cref = weak(complete)
  a.animate(20, function() end, {
    easing = a.linear,
    onComplete = function()
      local _ = complete
      error("complete boom")
    end,
  })
  local done = pcall(function()
    for _ = 1, 4 do
      h.advance(1 / a.FPS)
    end
  end)
  complete = nil
  gc()
  check(not done and h.callbackCount() == 0 and cref.value == nil, "completion error cleanup")
end)

run("cancellation inside onFrame suppresses completion", function()
  local a, h = fresh()
  local complete, timer, frames = 0, nil, 0
  timer = a.animate(100, function()
    frames = frames + 1
    a.stop(timer)
  end, { easing = a.linear, onComplete = function() complete = complete + 1 end })
  h.advance(1 / a.FPS)
  h.advance(1)
  equal(frames, 1, "single frame after callback cancellation")
  equal(complete, 0, "callback cancellation completion")
  equal(h.callbackCount(), 1, "retained cancelled callback ref")
  timer = nil
  gc()
  equal(h.callbackCount(), 0, "cancelled userdata gc releases callback ref")
end)

run("stack cleanup and fallback dismissAll use animator.stop", function()
  local stopped = {}
  local spy = { stop = function(timer) stopped[#stopped + 1] = timer end, fadeOut = function() end }
  package.loaded["lib.hud.animator"] = spy
  package.loaded["lib.hud.position"] = {}
  package.loaded["lib.hud.stack"] = nil
  local stack = require("lib.hud.stack")
  local canvas = { delete = function(self) self.deleted = true end, level = function() end }
  local t1, t2 = {}, {}
  local fallback = { id = "fallback", timers = { one = t1, two = t2 }, canvas = canvas }
  stack.register(fallback)
  stack.dismissAll({ animate = false })
  equal(#stopped, 2, "fallback dismiss timer count")
  check(
    (stopped[1] == t1 or stopped[1] == t2) and (stopped[2] == t1 or stopped[2] == t2) and stopped[1] ~= stopped[2],
    "fallback timers stopped"
  )
  stack.register({ id = "cleanup", timers = { only = t1 }, canvas = canvas })
  stack.cleanup()
  equal(#stopped, 3, "cleanup timer count")
  equal(stopped[3], t1, "cleanup timer stopped")
end)

run("notch stopAnimations dispatches every timer through animator.stop", function()
  local stopped = {}
  local spy = { stop = function(timer) stopped[#stopped + 1] = timer end }
  package.loaded["lib.hud.animator"] = spy
  package.loaded["lib.hud.notch"] = nil
  local notch = require("lib.hud.notch")
  notch.createDrop = function() return {}, { x = 0, y = 0 }, false, 10, 10 end
  local hud = notch.new()
  local t1, t2 = {}, {}
  hud.timers = { first = t1, second = t2 }
  hud:stopAnimations()
  equal(#stopped, 2, "notch timer count")
  check((stopped[1] == t1 and stopped[2] == t2) or (stopped[1] == t2 and stopped[2] == t1), "notch timers stopped")
end)

print(("%d passed, %d failed"):format(passes, failures))
if failures > 0 then os.exit(1) end
