-- TODO: ideally changes the /etc/hosts too
-- TODO: preferably puts a "25m..." menubar item, updates once a minute
-- TODO: should set slack as away eventually...

-- setup and vars

local hyper = require("hyper")
local hsApp = require("hs.application")

local pomoMode = hs.hotkey.modal.new()

local defaultPomodoroLength = 25

local timer = hs.timer.new(1, function() update() end)
local closedDistractions = {}
local string = ""

local startSound = hs.sound.getByName("Blow")
local stopSound = hs.sound.getByName("Submarine")

-- UI

function showPrompt(str)
  hs.alert.closeAll()
  hs.fnutils.imap(hs.screen.allScreens(), function(screen)
    return hs.alert.show(str, hs.alert.defaultStyle, screen, true)
  end)
  hs.timer.doAfter(2, function() pomoMode:exit() end)
end

function pomoMode:entered()
  prompt = "🍅 Press Enter to start Pomorodo! 🍅"
  if timerRunning then
    if timer:running() then
      pauseOrResume = "pause"
    else
      pauseOrResume = "resume"
    end

    prompt = string.format("🍅: %s\nPress Enter to stop\nPress Space to %s", timeString, pauseOrResume)
  end
  showPrompt(prompt)
end

function pomoMode:exited()
  hs.alert.closeAll()
end

function startOrStopPomodoro()
  if not timerRunning then
    startPomodoro()
  else
    stopPomodoro()
  end
end

function stopPomodoro()
  showPrompt("Stopping pomodoro!")
  stopSound:play()
  timerRunning = false
  for _, app in pairs(closedDistractions) do
    hsApp.launchOrFocus(app)
  end
  closedDistractions = {}
  timer:stop()
end

function startPomodoro()
  showPrompt("Pomodoro started...")
  startSound:play()
  timerRunning = true
  for _, app in pairs(config.applications) do
    pid = hsApp.find(app.name)
    if pid and app.distraction then
      table.insert(closedDistractions, app.name) -- keep track of it
      pid:kill()
    end
  end
  setupTimer()
  timer:start()
end

function pausePomodoro()
  if timer:running() then
    showPrompt("Pausing pomodoro...")
    timer:stop()
  else
    showPrompt("Resuming pomodoro...")
    timer:start()
  end
end

-- Keyboard bindings

hyper:bind({}, 'p', nil, function() pomoMode:enter() end)

pomoMode:bind('', 'escape', function() pomoMode:exit() end)
pomoMode:bind('', 'return', startOrStopPomodoro)
pomoMode:bind('', 'space', pausePomodoro)

-- Timer

update = function()
  local minutes = math.floor(timeLeft / 60)
  local seconds = timeLeft - (minutes * 60)
  timeString = string.format("%02d:%02d", minutes, seconds)

  if not timer then return end
  timeLeft = timeLeft - 1
  if timeLeft <= 0 then
    stopPomodoro()
  end
end

function setupTimer()
  timeLeft = hs.timer.minutes(defaultPomodoroLength)
end
