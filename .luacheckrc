max_line_length = false
codes = true

exclude_files = {
  "tests/",
}

ignore = {
  "212", -- Unused argument
  "213", -- Unused variable
  "631", -- Line is too long
  "122", -- Setting a readonly global
  "113", -- Global thingamadoogie
}

read_globals = {
  "hs",
  "vim",
  "safe_require",
}

globals = {
  "mega",
}
