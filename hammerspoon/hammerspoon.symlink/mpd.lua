DEBUGMPD = false

local mpd = {}

require 'utils'
icons = require 'icons'

mpd.logger = hs.logger.new("mpd")
mpd.setLogLevel = mpd.logger.setLogLevel
local logger = mpd.logger

local FIRSTLINE = 0
local DEBUG = -2

local function mpdMenuDisplay()
  mpdMenuPlayPause:setIcon(mpd.status.state == "play" and icons.pause or icons.play)
  local c = mpd.track.current
  local n = mpd.track.next

  local currentTooltip = (c and c.Artist and c.Artist.." - " or "")..(c and c.Title or "-")
  mpdMenuPlayPause:setTooltip(currentTooltip)
  mpdMenuNext:setTooltip(n and ((n.Artist and n.Title) and (n.Artist.." - "..n.Title) or n.Name and n.Name) or "END")

  if mpd.status.state == "play" and not (c and c.Title) then
    hs.timer.doAfter(0.2, mpd.updateStatus)
  end
end

local function notifyChange(newSong)
  if not newSong.file then logger.e("no filename!"); return end
  local image = newSong.file:sub(1,7) ~= "http://" and hs.image.imageFromMediaFile("~/Music/"..newSong.file) or nil
  if type(mpd.track.current) == "table" and type(newSong) == "table" and not tableCompare(newSong, mpd.track.current) then
    local notification = hs.notify.new({
      title = newSong.Title,
      informativeText = newSong.Artist and newSong.Artist or newSong.Name and newSong.Name or "",
      -- contentImage = image,
      })
    if image then notification:setIdImage(image) end
    notification:send()
  end
end

tableMerge(mpd, {
  host ="localhost",
  port = 6600,
  version = nil,
  delimiter = "OK\n",
  currentTags = {},
  mpdError = nil,
  buffer = nil,
  parsed = nil,
  status = {},
  track = {},
  albums = {},
  playlist = {},
  socket = hs.socket.new(),

  started = function()
    local output, status = hs.execute("ps -Ac -o pid,comm|grep mpd")
    return status and output:find("mpd") and true or false
  end,

  start = function() hs.execute("mpd", true) end,

  connect = function()
    if MPD_AUTOSTART and not mpd.started() then mpd.start() end
    logger.i("connecting...")
    mpd.socket:setCallback(mpd.readCallback):connect(mpd.host, mpd.port)
    mpd.read(mpd.tag("CONNECT"))
  end,

  disconnect = function()
    logger.i("disconnecting...")
    mpd.socket:disconnect()
  end,

  send = function(cmd)
    if not mpd.socket:connected() then mpd.connect() end
    logger.i("sending command: ", cmd)
    mpd.socket:write(cmd.."\n")
  end,

  read = function(tag)
    tag = tag or mpd.tag("OK")
    logger.i("reading with tag", tag)
    mpd.buffer = {}
    queue(mpd.currentTags, tag)
    mpd.socket:read("\n", FIRSTLINE)
  end,

  sendrecv = function(cmd, tag)
    mpd.send(cmd)
    mpd.read(tag)
  end,

  checkError = function(data)
    if data:find("^ACK") then
      mpd.mpdError = data
      hs.alert("MPD Error:\n\n"..data)
      local tag = dequeue(mpd.currentTags)
      logger.e("tag failed: ", mpd.tags[tag])
      return true
    end
    return false
  end,

  readCallback = function(data, tag)
    logger.i("tag", tag, mpd.tags[tag])
    logger.i("queued tags: ", hs.inspect(hs.fnutils.mapCat(mpd.currentTags, function(t) return {mpd.tags[t]} end)))
    if DEBUGMPD then print(data) end

    if mpd.checkError(data) then return end
    if tag == DEBUG then print("DEBUG:\n", data); return end

    if tag == FIRSTLINE then
      local t = dequeue(mpd.currentTags)
      if t == mpd.tag("CONNECT") then
        mpd.tagReaders[mpd.tags[t]].fn(data)
      elseif data == mpd.delimiter then
        mpd.tagReaders[mpd.tags[t]].fn(data)
      else
        mpd.firstLine = data
        mpd.socket:read(mpd.delimiter, t)
      end
      return
    end

    data = mpd.firstLine..data
    if not data:find("\nOK\n$") then
      mpd.firstLine = data
      mpd.socket:read(mpd.delimiter, tag)
      return
    end

    local t = mpd.tags[tag]
    local tagReader = mpd.tagReaders[t]

    local _, _, output = data:find("(.*)"..mpd.delimiter.."$")
    output = output:sub(1, #output - 1)

    local buffer = hs.fnutils.split(output, "\n") or nil
    mpd.buffer = buffer
    local parsed = mpd.parseBuffer(tagReader.form, mpd.buffer)
    mpd.parsed = parsed
    logger.i("Calling callback for tag: ", tag, mpd.tags[tag])
    tagReader.fn(parsed)
  end,

  parseBuffer = function(rform, buf)
    if rform == "table" or rform == "list" then
      local t = {}
      for _,line in ipairs(buf) do
        local k, v = line:match("(.-): (.*)")
        if k and v then
          if rform == "table" then t[k] = v else t[#t+1] = v end
        end
      end
      res = t
    elseif rform == "table-list" then
      local ts, t = {}, {}
      for _,line in ipairs(buf) do
        local k, v = line:match("(.-): (.*)")
        if k and v then
          if t[k] then ts[#ts+1] = t; t = {} end
          t[k] = v
        end
      end
      ts[#ts+1] = t
      res = ts
    elseif rform == "line" then
      res = table.concat(buf, "\n")
    else
      return false, ("match failed: " .. rform)
    end
    return res
  end,
})

mpd.tagReaders = {
  CONNECT = { form = "line", fn = function(data) logger.i("CONNECTED: "..data); mpd.version = data end },
  OK = { form = "line", fn = function(data) logger.i(data) end },
  PLAYID = { form = "table", fn = function(data)
    logger.i("playing id: ", data)
    if data.Id then mpd.playid(data.Id) end
    end
  },
  STATUS = { form = "table", fn = function(data)
    mpd.status = data
    mpd.currentsong()
    end
  },
  CURRENTSONG = { form = "table", fn = function(data)
    notifyChange(data)
    mpd.track.current = data
    mpd.nextsong()
    end
  },
  NEXTSONG = { form = "table", fn = function(data)
    mpd.track.next = data
    end
  },
  SEARCH = { form = "table-list", fn = function(data)
    searchChooser:choices(makeChoicesFromTracks(data))
    end
  },
  PLAYLISTSEARCH = { form = "table-list", fn = function(data)
    searchChooser:choices(makeChoicesFromTracks(data))
    end
  },
  PLAYLISTINFO = { form = "table-list", fn = function(data)
    mpd.playlist = data
    playlistChooser:choices(makeChoicesFromTracks(mpd.playlist))
    end
  },
  LISTALBUMARTIST = { form = "table-list", fn = function(data)
    mpd.albums = data
    albumChooser:choices(makeChoicesFromAlbums(mpd.albums))
    end
  },
}

mpd.tags = keys(mpd.tagReaders)
mpd.tag = function(tag) return hs.fnutils.indexOf(mpd.tags, tag) end
local tag = mpd.tag

hs.fnutils.each({ "play", "pause", "next", "previous", "stop", "clear", "shuffle", "ping" }, function(item)
  mpd[item] = function() mpd.sendrecv(item) end
end)

mpd.currentsong = function() mpd.sendrecv("currentsong", tag("CURRENTSONG")) end
mpd.getstatus = function() mpd.sendrecv("status", tag("STATUS")) end
mpd.playlistinfo = function(starting, ending) mpd.sendrecv("playlistinfo", tag("PLAYLISTINFO")) end
mpd.listalbumartist = function() mpd.sendrecv("list album group albumartist group artist", tag("LISTALBUMARTIST")) end
mpd.addid = function(file) mpd.sendrecv(fmt("addid %q", file)) end
mpd.addplayid = function(file) mpd.sendrecv(fmt("addid %q", file), tag("PLAYID")) end

mpd.search = function(str, kind)
  kind = kind or "any"
  mpd.sendrecv(fmt("search %q %q", kind, str), tag("SEARCH"))
end

mpd.playlistsearch = function(str)
  kind = kind or "any"
  mpd.sendrecv(fmt("playlistsearch %q %q", kind, str), tag("PLAYLISTSEARCH"))
end

mpd.findadd = function(str, kind)
  kind = kind or "any"
  mpd.sendrecv(fmt("findadd %q %q", kind, str))
end

mpd.playitemonplaylist = function(item, kind)
  kind = kind or "any"
  mpd.sendrecv(fmt("playlistsearch %q %q", kind, item), tag("PLAYID"))
end

mpd.nextsong = function()
  mpd.track.next = nil
  if not mpd.status.nextsong then return end
  mpd.sendrecv("playlistinfo "..mpd.status.nextsong, tag("NEXTSONG"))
end

mpd.playid = function(id)
  mpd.sendrecv(fmt("playid %d", id))
  mpd.updateStatus()
end

mpd.updateStatus = function()
  mpd.getstatus()
  hs.timer.doAfter(0.2, mpdMenuDisplay)
end

mpd.command = function(cmd, tag) mpd.sendrecv(cmd, tag) end
mpd.debug = function(cmd) mpd.send(cmd); mpd.socket:read("\n", DEBUG) end

function makeChoicesFromTracks(tracks)
  return hs.fnutils.imap(tracks, function(track)
    if track.file == nil then return nil end
    return {
      text = track.Title or track.Name,
      subText = (track.Artist or "")..(track.Album and " - "..track.Album or "")..(track.Name or ""),
      image = track.file and hs.image.imageFromMediaFile("~/Music/"..track.file) or nil,
      file = (track.file and track.file or ""),
      Id = track.Id or nil
    }
  end)
end

function makeChoicesFromAlbums(albums)
  return hs.fnutils.imap(albums, function(album)
    return {
      text = album.Album,
      subText = album.Artist,
      image = hs.image.imageFromMediaFile("~/Music/"..album.AlbumArtist:gsub("Various Artists", "Compilations"):gsub("[/]", "_"):gsub("[?%.]$","_").."/"..album.Album:gsub("[:/\"]", "_"):gsub("[?%.]$","_")),
      album = album.Album,
    }
  end)
end

local function playChoice(choice)
  if choice.Id then
    mpd.playid(choice.Id)
  elseif choice.file then
    mpd.addplayid(choice.file)
  elseif choice.album then
    mpd.findadd(choice.album, "album")
  end
end

searchChooser=hs.chooser.new(playChoice):width(30):searchSubText(true):queryChangedCallback(function(query)
    if #query >= 2 and query:sub(1,2) == "!p" then
      local _, _, q = query:find("^!p(.*)")
      mpd.playlistsearch(q)
      return
    end
    if #query > 2 then mpd.search(query) end
  end)
hs.hotkey.bind(hyper, "p", function() searchChooser:show() end)

albumChooser=hs.chooser.new(function(choice) mpd.findadd(choice.album, "album") end):width(30):searchSubText(true)
hs.hotkey.bind(hyper, "a", function() albumChooser:show() end)

playlistChooser=hs.chooser.new(playChoice):width(30):searchSubText(true)
hs.hotkey.bind(hyper, "l", function() mpd.playlistinfo(); playlistChooser:show() end)

-- menubars
mpdMenuNext = hs.menubar.new():setIcon(icons.next):setClickCallback(function()
    mpd.next()
    mpd.updateStatus()
  end)
mpdMenuPlayPause = hs.menubar.new():setClickCallback(function()
    if mpd.status.state == "stop" then mpd.play() else mpd.pause() end
    mpd.updateStatus()
  end)
mpdMenuPrev = hs.menubar.new():setIcon(icons.prev):setClickCallback(function()
    mpd.previous()
    mpd.updateStatus()
  end)

mpdMenu = hs.menubar.new():setTitle("🎵"):setMenu(hs.fnutils.concat({
    { title = "Music Player Daemon", fn = function() print(mpd.version) end },
    { title = "-" },
    { title = "play", fn = mpd.play },
    { title = "pause", fn = mpd.pause },
    { title = "shuffle", fn = mpd.shuffle },
    { title = "stop", fn = mpd.stop },
    { title = "clear", fn = mpd.clear },
    { title = "-" },
    { title = "SomaFM", fn = function() mpd.sendrecv("load soma") end },
  }, hs.fnutils.imap({
    "beatblender","bootliquor","brfm","cliqhop","covers",
    "digitalis","doomed","dronezone","dubstep","groovesalad","illstreet",
    "indiepop","lush","missioncontrol","poptron","secretagent","sf1033",
    "sonicuniverse","spacestation","suburbsofgoa","thetrip","u80s"
  }, function(somaStation) return {
      title = somaStation,
      indent = 1,
      fn = function() mpd.playitemonplaylist(somaStation.."-128-mp3", "file") end
  } end)))

-- start everything up
mpd.listalbumartist()

mpdStarter = hs.timer.doAfter(1, function()
  mpd.playlistinfo()
  mpd.updateStatus()
end)

statusTimer = hs.timer.doEvery(10, mpd.updateStatus)

return mpd
