-- TODO: prompt whether you should continue on a stop...
-- TODO: ideally changes the /etc/hosts too
-- TODO: preferably puts a "25m..." menubar item, updates once a minute
-- TODO: should set slack as away eventually...

-- setup and vars

local hyper = require("hyper")
local hsApp = require("hs.application")

local pomoMode = hs.hotkey.modal.new()

local numberOfPoms = 1
local pomLength = 30

local timer = hs.timer.new(1, function() update() end)
local closedDistractions = {}
local string = ""

local startSound = hs.sound.getByName("Blow")
local stopSound = hs.sound.getByName("Submarine")

local alert = require("hs.alert")
      alert.defaultStyle.textStyle =
      { paragraphStyle = { alignment = "center" } }
-- UI

function showPrompt(str)
  alert.closeAll()
  hs.fnutils.imap(hs.screen.allScreens(), function(screen)
    return alert.show(str, alert.defaultStyle, screen, true)
  end)
  hs.timer.doAfter(10, function() pomoMode:exit() end)
end

function pomoMode:entered()
  prompt = string.format("Press Enter to start Pomorodo for %sm!\n%s\n(Press ⬆ and ⬇ to change duration\nPress R to reset.\nHold Shift to create calendar block.)", numberOfPoms * pomLength, string.rep("🍅", numberOfPoms))
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
  alert.closeAll()
end

function startOrStopPomodoro(calendarEvent)
  calendarEvent = calendarEvent or false

  if not timerRunning then
    startPomodoro(calendarEvent)
  else
    stopPomodoro()
  end
end

function stopPomodoro()
  showPrompt("Stopping pomodoro!")
  stopSound:play()
  timerRunning = false
  for _, app in pairs(closedDistractions) do
    hsApp.launchOrFocusByBundleID(app)
  end
  closedDistractions = {}
  timer:stop()
end

function startPomodoro(makeCalendarEvent)
  showPrompt("Pomodoro started...")
  startSound:play()
  timerRunning = true
  if makeCalendarEvent then
    hs.urlevent.openURL(
      string.format("x-fantastical2://parse?add=1&s=%s%sm",
        hs.http.encodeForQuery("Focus Session starting now for "),
        numberOfPoms * pomLength))
  end
  for _, app in pairs(config.applications) do
    pid = hsApp.find(app.bundleID)
    if pid and app.distraction then
      table.insert(closedDistractions, app.bundleID) -- keep track of it
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

function increaseDuration()
  numberOfPoms = numberOfPoms + 1
  pomoMode:entered()
end

function decreaseDuration()
  if numberOfPoms > 1 then
    numberOfPoms = numberOfPoms - 1
    pomoMode:entered()
  end
end

function resetDuration()
  numberOfPoms = 1
  pomoMode:entered()
end

-- Keyboard bindings

hyper:bind({}, 'p', nil, function() pomoMode:enter() end)

pomoMode:bind('', 'escape', function() pomoMode:exit() end)
pomoMode:bind('', 'return', startOrStopPomodoro)
pomoMode:bind('shift', 'return', function() startOrStopPomodoro(true) end)
pomoMode:bind('', 'space', pausePomodoro)
pomoMode:bind('', 'up', increaseDuration)
pomoMode:bind('', 'down', decreaseDuration)
pomoMode:bind('', 'r', resetDuration)

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
  timeLeft = hs.timer.minutes(numberOfPoms * pomLength)
end
