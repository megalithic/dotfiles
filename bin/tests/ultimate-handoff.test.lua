-- Run from the repo root: lua bin/tests/ultimate-handoff.test.lua
-- Mock Rex: no sessions, config reloads, network calls, or browser opens.
local actions, calls = {}, {}
local cwd = '/tmp/worktree with "quotes"'
local url = "http://127.0.0.1:4749"
local body = "encoded request body"
local busy = false
rex = {
  action = function(action) actions[action.name] = action end,
  block = { call = function(_, method)
    assert(method == "process")
    return { foreground = { cwd = cwd } }
  end },
  json = {
    encode = function(value)
      assert(value.args.cwd == cwd and value.args.from.label == "rex")
      return body
    end,
    decode = function(value)
      if value == "instance" then return { url = url } end
      if value == "pickup" then return { result = { conversation = 123, url = url .. "/?conversation=123" } } end
      if value == "busy" then return { error = "Pi is working; wait until it is idle" } end
      error("unexpected JSON: " .. value)
    end,
  },
  exec = function(argv, opts)
    calls[#calls + 1] = { argv = argv, opts = opts }
    if argv[1]:match("/ultimate%-instance$") then
      assert(argv[2] == cwd and opts.timeout == 5)
      return { ok = true, stdout = "instance" }
    end
    if argv[1] == "/usr/bin/curl" then
      local expected = {
        "/usr/bin/curl", "--fail-with-body", "-sS", "--max-time", "60",
        "-H", "Origin: " .. url, "-H", "Content-Type: application/json",
        "--data-binary", body, url .. "/api/extensions/pi-sessions/actions/pickup",
      }
      assert(#argv == #expected and opts.timeout == 65)
      for i, value in ipairs(expected) do assert(argv[i] == value, "curl argument " .. i) end
      return { ok = not busy, stdout = busy and "busy" or "pickup", stderr = "curl: (22) HTTP 500" }
    end
    assert(argv[1] == "/usr/bin/open" and argv[2] == url .. "/?conversation=123")
    return { ok = true }
  end,
}
dofile("config/rex/ultimate.lua")
local action = assert(actions.ultimate_handoff)
assert(action.title == "Hand off to Ultimate" and action.category == "Ultimate")
action.run({ block_id = "throwaway" })
assert(#calls == 3)
print("ok - pickup encodes args, posts with Origin and opens the returned conversation")
busy, calls = true, {}
local ok, err = pcall(action.run, { block_id = "throwaway" })
assert(not ok and err == "Pi is working; wait until it is idle", tostring(err))
assert(#calls == 2)
print("ok - server refusal surfaces verbatim without opening a browser")
