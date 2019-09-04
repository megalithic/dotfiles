std = {
  globals = {"hs"}, -- these globals can be set and accessed.
}

globals = {
  "hs",
  "hyper",
  "rawrequire",
  "ls",
  "spoon",
  "success",
  "assertIsEqual",
  "pairs",
  "require",
}

ignore = {
  "111",
  "112",
  "631" -- Line is too long.
}

stds.hammerspoon = {
  globals = {
    spoon = { other_fields = true },
    hs = { other_fields = true },
  },
}

std = 'max+hammerspoon'

files["/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/**/*"].read_globals = { 'hs', 'spoon' }

-- vim: set filetype=lua:
