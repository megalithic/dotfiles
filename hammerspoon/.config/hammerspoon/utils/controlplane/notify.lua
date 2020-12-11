local IMAGE_PATH = os.getenv('HOME') .. '/.hammerspoon/assets/system-preferences.png'

return function(message)
  hs.notify.new({
    title        = 'ControlPlane',
    subTitle     = message,
    contentImage = IMAGE_PATH
  }):send()
end
