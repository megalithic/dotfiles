module = {}

module.init = (function()
  log.df('[do-not-disturb] - creating appWatcher for DND')

  local appWatcher = hs.application.watcher.new(function(name, eventType, app)
    log.df('[dnd] app watched for %s (%s), with eventType of %s', name, app, eventType)

    if config.applications[name].name == name and config.applications[name].dnd == true then
      if eventType == 4 or eventType == 5 then
        log.df('[do-not-disturb] - application %s launched; turning ON do-not-disturb mode.(%s)', name, app)
        hs.execute('do-not-disturb on', true)
      elseif eventType == 6 and utils.tableLength(app:allWindows()) == 0 then
        log.df('[do-not-disturb] - application %s terminated; turning OFF do-not-disturb mode. (%s)', name, app)
        hs.execute('do-not-disturb off', true)
      else
        return
      end
    else
      return
    end
  end)

  appWatcher:start()
end)

return module
