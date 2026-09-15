import AppKit
import Foundation

func consumeModeOption(
  _ argument: String, _ next: () -> String, _ options: inout Options, _ mode: inout Mode?
) -> Bool {
  switch argument {
  case "--list-apps": mode = .list
  case "--capture-pid":
    mode = .capture
    guard let value = Int32(next()), value > 0 else { fail("invalid PID") }
    options.pid = pid_t(value)
  case "--route-pid":
    mode = .route
    guard let value = Int32(next()), value > 0 else { fail("invalid PID") }
    options.pid = pid_t(value)
  default: return false
  }
  return true
}
func consumeTextOption(_ argument: String, _ next: () -> String, _ options: inout Options) -> Bool {
  switch argument {
  case "--output": options.output = next()
  case "--host": options.host = next()
  case "--helper": options.helper = next()
  case "--device-uid": options.deviceUID = next()
  default: return false
  }
  return true
}
func consumeNumericOption(_ argument: String, _ next: () -> String, _ options: inout Options)
  -> Bool
{
  switch argument {
  case "--seconds":
    guard let value = Double(next()), value > 0 else { fail("seconds must be positive") }
    options.seconds = value
  case "--port":
    guard let value = Int32(next()), (1...65_535).contains(value) else { fail("invalid port") }
    options.port = value
  case "--volume":
    guard let value = Int32(next()), (0...100).contains(value) else {
      fail("volume must be 0...100")
    }
    options.volume = value
  default: return false
  }
  return true
}
func validateRouteOptions(_ options: Options) {
  let airplay = options.host != nil || options.port != nil || options.helper != nil
  let local = options.deviceUID != nil
  guard airplay != local else {
    fail("route requires exactly one destination: --host/--port/--helper or --device-uid")
  }
  if airplay {
    guard options.pid != nil, options.host != nil, options.port != nil, options.helper != nil else {
      fail("route requires --route-pid, --host, --port, and --helper")
    }
  } else if options.pid == nil {
    fail("route requires --route-pid and --device-uid")
  }
}
func parseOptions() -> Options {
  var options = Options()
  var index = 1
  var requestedMode: Mode?
  while index < CommandLine.arguments.count {
    let argument = CommandLine.arguments[index]
    func next() -> String {
      index += 1
      guard index < CommandLine.arguments.count else { fail("missing value for \(argument)") }
      return CommandLine.arguments[index]
    }
    guard
      consumeModeOption(argument, next, &options, &requestedMode)
        || consumeTextOption(argument, next, &options)
        || consumeNumericOption(argument, next, &options)
    else { fail("unknown argument \(argument)") }
    index += 1
  }
  guard let mode = requestedMode else { fail("specify --list-apps, --capture-pid, or --route-pid") }
  options.mode = mode
  guard mode == .list || options.seconds != nil else { fail("--seconds is required") }
  if mode == .capture {
    guard options.pid != nil, options.output != nil else {
      fail("capture requires --capture-pid and --output")
    }
  }
  if mode == .route { validateRouteOptions(options) }
  return options
}
func listApps() {
  for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
    print("\(app.localizedName ?? "")\t\(app.bundleIdentifier ?? "")\t\(app.processIdentifier)")
  }
}
