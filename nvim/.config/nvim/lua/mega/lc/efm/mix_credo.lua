return {
  lintCommand = "mix credo suggest --format=flycheck --read-from-stdin ${INPUT}",
  lintStdin = true,
  lintIgnoreExitCode = true,
  lintFormats = {"%f:%l:%c: %m"},
  rootMarkers = {"mix.lock"} -- for some reason, only mix.lock works in vpp
}
