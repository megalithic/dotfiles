---@diagnostic disable: undefined-global
return {
  snippet(
    { trig = "~H", name = "Heex Sigil", dscr = "Create an inline Heex template" },
    fmt([[
      ~H"""
        {}
      """
    ]])
  ),
}
