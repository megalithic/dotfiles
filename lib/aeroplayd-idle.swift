import Darwin
import Foundation

let defaultIdleAudioTimeoutSeconds = 60.0

private struct AeroConfig: Decodable {
  let idleAudioTimeoutSeconds: Double?

  enum CodingKeys: String, CodingKey {
    case idleAudioTimeoutSeconds = "idle_audio_timeout_seconds"
  }
}

func loadIdleAudioTimeoutSeconds(
  at path: String = NSHomeDirectory() + "/.config/aeroplayd/config.json"
) -> Double {
  guard FileManager.default.fileExists(atPath: path) else {
    return defaultIdleAudioTimeoutSeconds
  }
  do {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let value = try JSONDecoder().decode(AeroConfig.self, from: data).idleAudioTimeoutSeconds
    guard let value else { return defaultIdleAudioTimeoutSeconds }
    guard value.isFinite, value > 0 else {
      fputs("aeroplayd: idle_audio_timeout_seconds must be positive; using 60\n", stderr)
      return defaultIdleAudioTimeoutSeconds
    }
    return value
  } catch {
    fputs("aeroplayd: cannot read config; using 60: \(error)\n", stderr)
    return defaultIdleAudioTimeoutSeconds
  }
}

struct IdleAudioTimer {
  let timeoutSeconds: Double
  var lastMeaningfulCallback: Int
  var deadline: TimeInterval

  init(
    timeoutSeconds: Double, meaningfulAudioCallbacks: Int,
    now: TimeInterval = ProcessInfo.processInfo.systemUptime
  ) {
    self.timeoutSeconds = timeoutSeconds
    lastMeaningfulCallback = meaningfulAudioCallbacks
    deadline = now + timeoutSeconds
  }

  mutating func hasExpired(
    meaningfulAudioCallbacks: Int,
    now: TimeInterval = ProcessInfo.processInfo.systemUptime
  ) -> Bool {
    if meaningfulAudioCallbacks != lastMeaningfulCallback {
      lastMeaningfulCallback = meaningfulAudioCallbacks
      deadline = now + timeoutSeconds
    }
    return now >= deadline
  }
}
