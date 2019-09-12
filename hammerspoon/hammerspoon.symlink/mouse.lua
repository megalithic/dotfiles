local mouseCircle
local mouseCircleTimer

local M = {}

local removeCircle = function(mc)
  mc:hide(0.25)
  hs.timer.doAfter(1, function() mc:delete() end)
end

M.highlight = function ()
  local white = {["red"]=1,["blue"]=1,["green"]=1,["alpha"]=1}

  local radius = 40
  local diameter = (radius * 2)

  -- Delete an existing highlight if it exists
  if mouseCircle then
      removeCircle(mouseCircle)

      if mouseCircleTimer then
          mouseCircleTimer:stop()
      end
  end

  -- Get the current co-ordinates of the mouse pointer
  local mousepoint = hs.mouse.getAbsolutePosition()

  -- Prepare a circle around the mouse pointer
  mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x - radius, mousepoint.y - radius, diameter, diameter))
  mouseCircle:setStrokeColor(white)
  mouseCircle:setFill(true)
  mouseCircle:setStrokeWidth(1)
  mouseCircle:setAlpha(.5)
  mouseCircle:setFillColor(white, 90)
  mouseCircle:show()

  -- Set a timer to delete the circle
  mouseCircleTimer = hs.timer.doAfter(0.75, function() removeCircle(mouseCircle) end)
end

return M
