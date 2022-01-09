-- Modal class with smart autoexit timeout
local log = hs.logger.new("[ext.modal]", "warning") -- debug == 4, warning == 2

local IMAGE_PATH = os.getenv("HOME") .. "/.hammerspoon/assets/modal.png"

local Modal = {}

function Modal:new(opts)
  local obj = {
    exitTimeout = opts.timeout or 5,
    exitTimer = nil,
    modal = hs.hotkey.modal.new(opts.mod, opts.key)
  }

  function obj.modal:entered()
    if obj.exitTimeout > 0 then
      obj.exitTimer =
        hs.timer.doAfter(
        obj.exitTimeout,
        function()
          obj.modal:exit()
        end
      )
    end

    if log:getLogLevel() == 4 then
      hs.notify.new(
        {
          title = opts.name,
          subTitle = "Entered",
          contentImage = IMAGE_PATH
        }
      ):send()
    end
  end

  function obj.modal:exited()
    if log:getLogLevel() == 4 then
      hs.notify.new(
        {
          title = opts.name,
          subTitle = "Exited",
          contentImage = IMAGE_PATH
        }
      ):send()
    end
  end

  obj.modal:bind(
    {},
    "escape",
    function()
      obj.modal:exit()
    end
  )

  self.__index = self
  return setmetatable(obj, Modal)
end

function Modal:updateTimeout()
  if self.exitTimer then
    self.exitTimer:stop()
  end

  if self.exitTimeout > 0 then
    self.exitTimer =
      hs.timer.doAfter(
      self.exitTimeout,
      function()
        self.modal:exit()
      end
    )
  end
end

function Modal:bind(mod, key, pressedFn, releasedFn)
  -- can ommit mod, but breaks if no mod and no pressedFn
  if not pressedFn and not releasedFn then
    releasedFn = pressedFn
    pressedFn = key
    key = mod
    mod = {}
  end

  self.modal:bind(
    mod,
    key,
    function()
      self:updateTimeout()
      pressedFn()
    end,
    function()
      if releasedFn then
        self:updateTimeout()
        releasedFn()
      end
    end
  )
end

return Modal
