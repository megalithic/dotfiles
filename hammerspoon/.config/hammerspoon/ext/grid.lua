local cache  = {}
local module = { cache = cache }

module.toggleGrid = function()
  if cache.canvases ~= nil and #cache.canvases > 0 then
    hs.fnutils.each(cache.canvases, function(canvas)
      canvas:delete(0.5)
    end)

    hs.timer.doAfter(0.5, function()
      cache.canvases = {}
    end)

    return
  end

  hs.fnutils.each(hs.screen.allScreens(), function(screen)
    local grid  = hs.grid.getGrid(screen)
    local frame = screen:fullFrame()

    if hhtwm then
      local screenMarinFromTiling = hhtwm.screenMargin.top - hhtwm.margin / 2

      frame.y = frame.y + screenMarinFromTiling
      frame.h = frame.h - screenMarinFromTiling
    end

    local canvas = hs.canvas.new({
      x = frame.x,
      y = frame.y,
      w = frame.w,
      h = frame.h
    })

    for x = 1, grid.w - 1, 1 do
      canvas:appendElements({
        {
          type = 'segments',
          coordinates = {
            {
              x = frame.x + x * frame.w / grid.w,
              y = frame.y
            },
            {
              x = frame.x + x * frame.w / grid.w,
              y = frame.y + frame.h
            },
          },
          action = 'stroke',
          strokeColor = { white = 0.9 },
          strokeWidth = 1.0
        },
        {
          type = 'segments',
          coordinates = {
            {
              x = frame.x + x * frame.w / grid.w,
              y = frame.y
            },
            {
              x = frame.x + x * frame.w / grid.w,
              y = frame.y + frame.h
            },
          },
          action = 'stroke',
          strokeColor = { white = 0.1 },
          strokeWidth = 0.5
        },
      })
    end

    for y = 1, grid.h - 1, 1 do
      canvas:appendElements({
        {
          type = 'segments',
          coordinates = {
            {
              x = frame.x,
              y = frame.y + y * frame.h / grid.h
            },
            {
              x = frame.x + frame.w,
              y = frame.y + y * frame.h / grid.h
            },
          },
          action = 'stroke',
          strokeColor = { white = 0.9 },
          strokeWidth = 1.0
        },
        {
          type = 'segments',
          coordinates = {
            {
              x = frame.x,
              y = frame.y + y * frame.h / grid.h
            },
            {
              x = frame.x + frame.w,
              y = frame.y + y * frame.h / grid.h
            },
          },
          action = 'stroke',
          strokeColor = { white = 0.1 },
          strokeWidth = 0.5
        }
      })
    end

    canvas:alpha(0.5):show(0.5)

    if cache.canvases == nil then
      cache.canvases = {}
    end

    table.insert(cache.canvases, canvas)
  end)
end

return module
