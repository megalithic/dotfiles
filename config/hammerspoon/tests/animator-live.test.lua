-- Run in Hammerspoon: dofile("/path/to/config/hammerspoon/tests/animator-live.test.lua")
-- Inspect _animatorMemoryTest for the asynchronous result.
local animator = require("lib.hud.animator")
assert(not _animatorMemoryTest or _animatorMemoryTest.status ~= "running", "Animation test already running")

local result =
  { status = "running", batches = 0, animations = 0, completed = 0, cancelled = 0, huds = 0, dismissed = 0 }
_G._animatorMemoryTest = result
local weak = setmetatable({}, { __mode = "v" })
local tracked, finished = 0, 0
local settleAt = 0
local deadline = hs.timer.secondsSinceEpoch() + 30
local driver

local function track(value)
  tracked = tracked + 1
  weak[tracked] = value
end

local function startAnimation(mode)
  local canvas = hs.canvas.new({ x = 20, y = 80, w = 32, h = 32 })
  canvas:appendElements({ type = "rectangle", action = "fill", fillColor = { white = 1 } })
  canvas:alpha(0.01):show()
  local timer
  timer = animator.animate(50, function(progress)
    canvas:alpha(progress * 0.01)
    if mode == "midway" then
      animator.stop(timer)
      canvas:delete()
      finished = finished + 1
      result.cancelled = result.cancelled + 1
    end
  end, {
    easing = animator.linear,
    onComplete = function()
      canvas:delete()
      finished = finished + 1
      result.completed = result.completed + 1
    end,
  })
  track(timer)
  track(canvas)
  if mode == "immediate" then
    animator.stop(timer)
    canvas:delete()
    finished = finished + 1
    result.cancelled = result.cancelled + 1
  end
  result.animations = result.animations + 1
end

local function startHUD(kind)
  local opts = {
    id = "animator-memory-" .. kind .. "-" .. result.batches,
    duration = 0.03,
    animation = 25,
    position = "bottom-left",
    onDismiss = function() result.dismissed = result.dismissed + 1 end,
  }
  local hud
  if kind == "alert" then
    opts.size = "small"
    hud = HUD.alert("Animation memory test", opts)
  else
    opts.title = "Animation memory test"
    opts.appBundleID = "org.hammerspoon.Hammerspoon"
    hud = HUD.toast(opts)
  end
  track(hud)
  track(hud.canvas)
  for _, timer in pairs(hud.timers) do
    track(timer)
  end
  result.huds = result.huds + 1
end

local function step()
  assert(hs.timer.secondsSinceEpoch() < deadline, "Animation memory test timed out")
  if finished < result.animations or result.dismissed < result.huds or hs.timer.secondsSinceEpoch() < settleAt then
    return
  end

  -- Canvas finalizers release mouse callbacks that keep HUDs alive for another cycle.
  collectgarbage("collect")
  collectgarbage("collect")
  collectgarbage("collect")
  for i = 1, tracked do
    assert(weak[i] == nil, "Animation retained timer or canvas " .. i)
  end

  if result.batches == 5 then
    assert(result.completed == 100 and result.cancelled == 200, "Unexpected animation completion counts")
    assert(result.huds == 10 and result.dismissed == 10, "Unexpected HUD dismissal counts")
    driver:stop()
    driver = nil
    result.status = "passed"
    print("ANIMATOR_MEMORY_PASS " .. hs.json.encode(result))
    return
  end

  result.batches = result.batches + 1
  settleAt = hs.timer.secondsSinceEpoch() + 0.5 -- Allow anonymous stack animations to finish.
  startHUD("alert")
  startHUD("toast")
  for _ = 1, 20 do
    startAnimation("complete")
    startAnimation("immediate")
    startAnimation("midway")
  end
end

driver = hs.timer
  .new(0.1, function()
    local ok, err = pcall(step)
    if not ok then
      driver:stop()
      driver = nil
      result.status = "failed"
      result.error = tostring(err)
      print("ANIMATOR_MEMORY_FAIL " .. result.error)
    end
  end)
  :start()
return "Animation memory test started"
