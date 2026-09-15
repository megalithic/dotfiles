import AVFoundation
import AppKit
import AudioToolbox
import CoreAudio
import Darwin
import Foundation
import Synchronization

enum Mode { case list, capture, route }
struct Options {
  var mode: Mode = .list
  var pid: pid_t?
  var seconds: Double?
  var output: String?
  var host: String?
  var port: Int32?
  var helper: String?
  var deviceUID: String?
  var volume: Int32 = 15
  var bundleID: String?
  var idleAudioTimeoutSeconds: Double?
}
struct AeroError: Error, CustomStringConvertible { let description: String }
func fail(_ message: String) -> Never {
  fputs("aeroplayd: \(message)\n", stderr)
  exit(1)
}
func propertyAddress(
  _ selector: AudioObjectPropertySelector,
  _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
) -> AudioObjectPropertyAddress {
  AudioObjectPropertyAddress(
    mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}
func getScalar<T>(
  _ object: AudioObjectID, _ selector: AudioObjectPropertySelector, default value: T,
  scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
) -> T? {
  var address = propertyAddress(selector, scope)
  var result = value
  var size = UInt32(MemoryLayout<T>.size)
  let status = withUnsafeMutableBytes(of: &result) { raw in
    guard let baseAddress = raw.baseAddress else { return OSStatus(kAudio_ParamError) }
    return AudioObjectGetPropertyData(object, &address, 0, nil, &size, baseAddress)
  }
  return status == noErr ? result : nil
}
func getString(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
  var address = propertyAddress(selector)
  var result: CFString = "" as CFString
  var size = UInt32(MemoryLayout<CFString>.size)
  let status = withUnsafeMutablePointer(to: &result) {
    AudioObjectGetPropertyData(object, &address, 0, nil, &size, $0)
  }
  return status == noErr ? result as String : nil
}
func translatePID(_ pid: pid_t) -> AudioObjectID? {
  var address = propertyAddress(kAudioHardwarePropertyTranslatePIDToProcessObject)
  var result = kAudioObjectUnknown
  var processID = pid
  var size = UInt32(MemoryLayout<AudioObjectID>.size)
  let status = AudioObjectGetPropertyData(
    AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<pid_t>.size), &processID,
    &size, &result)
  return status == noErr ? result : nil
}
// UI live volume in percent; -1 means unset, so CLI routes keep Options.volume.
let liveVolumePercent = Atomic<Int32>(-1)

// Maps WKWebView XPC audio helpers (com.apple.WebKit.GPU) back to the selected app.
private let responsiblePID = dlsym(
  UnsafeMutableRawPointer(bitPattern: -2), "responsibility_get_pid_responsible_for_pid"
).map { unsafeBitCast($0, to: (@convention(c) (pid_t) -> pid_t).self) }

func processObjects(for pid: pid_t, bundleID: String?) -> [AudioObjectID] {
  var address = propertyAddress(kAudioHardwarePropertyProcessObjectList)
  var size: UInt32 = 0
  guard
    AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
      == noErr
  else { return [] }
  var objects = [AudioObjectID](
    repeating: kAudioObjectUnknown, count: Int(size) / MemoryLayout<AudioObjectID>.size)
  guard
    AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &objects) == noErr
  else { return [] }
  var result = Set<AudioObjectID>()
  if let translated = translatePID(pid), translated != kAudioObjectUnknown { result.insert(translated) }
  for object in objects {
    guard let objectPID: pid_t = getScalar(object, kAudioProcessPropertyPID, default: pid_t(-1))
    else { continue }
    if objectPID == pid || responsiblePID?(objectPID) == pid {
      result.insert(object)
      continue
    }
    guard let selectedBundle = bundleID,
      let objectBundle = getString(object, kAudioProcessPropertyBundleID),
      objectBundle == selectedBundle || objectBundle.hasPrefix(selectedBundle + ".")
    else { continue }
    result.insert(object)
  }
  return result.sorted()
}

final class Recorder {
  let samples: UnsafeMutablePointer<Float>
  let capacity: Int
  let channels: Int
  var frames = 0
  var overruns = 0
  init(capacity: Int, channels: Int) {
    self.capacity = capacity
    self.channels = channels
    samples = .allocate(capacity: capacity * channels)
    samples.initialize(repeating: 0, count: capacity * channels)
  }
  deinit {
    samples.deinitialize(count: capacity * channels)
    samples.deallocate()
  }
}

func floatFrameCount(_ buffers: UnsafeMutableAudioBufferListPointer) -> Int {
  guard !buffers.isEmpty else { return 0 }
  let first = buffers[0]
  let channels = Int(first.mNumberChannels)
  if buffers.count == 1 {
    guard channels > 0 else { return 0 }
    return Int(first.mDataByteSize) / (channels * MemoryLayout<Float>.size)
  }
  var frames = Int.max
  for index in 0..<buffers.count {
    frames = min(frames, Int(buffers[index].mDataByteSize) / MemoryLayout<Float>.size)
  }
  return frames == Int.max ? 0 : frames
}

func copyAudio(_ buffers: UnsafeMutableAudioBufferListPointer, into recorder: Recorder) {
  guard !buffers.isEmpty else { return }
  let first = buffers[0]
  let sourceChannels = Int(first.mNumberChannels)
  let interleaved = buffers.count == 1 && sourceChannels > 1
  let frames = floatFrameCount(buffers)
  let count = min(frames, max(0, recorder.capacity - recorder.frames))
  if count < frames { recorder.overruns += frames - count }
  let start = recorder.frames
  for frame in 0..<count {
    for channel in 0..<recorder.channels {
      if interleaved, let data = first.mData {
        recorder.samples[(start + frame) * recorder.channels + channel] =
          data.assumingMemoryBound(to: Float.self)[
            frame * sourceChannels + min(channel, sourceChannels - 1)]
      } else if let data = buffers[min(channel, buffers.count - 1)].mData {
        recorder.samples[(start + frame) * recorder.channels + channel] =
          data.assumingMemoryBound(to: Float.self)[frame]
      } else {
        recorder.samples[(start + frame) * recorder.channels + channel] = 0
      }
    }
  }
  recorder.frames += count
}
let captureIOProc: AudioDeviceIOProc = { _, _, input, _, _, _, clientData in
  guard let clientData else { return noErr }
  let recorder = Unmanaged<Recorder>.fromOpaque(clientData).takeUnretainedValue()
  copyAudio(
    UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input)), into: recorder)
  return noErr
}

final class StereoRing {
  let capacity: Int
  let samples: UnsafeMutablePointer<Float>
  let writeIndex = Atomic<Int>(0)
  let readIndex = Atomic<Int>(0)
  let captured = Atomic<Int>(0)
  let overruns = Atomic<Int>(0)
  let underruns = Atomic<Int>(0)
  let outputFrames = Atomic<Int>(0)
  let latestLevelBits = Atomic<UInt32>(0)
  let meaningfulAudioCallbacks = Atomic<Int>(0)
  init(capacity: Int) {
    self.capacity = capacity
    samples = .allocate(capacity: capacity * 2)
    samples.initialize(repeating: 0, count: capacity * 2)
  }
  deinit {
    samples.deinitialize(count: capacity * 2)
    samples.deallocate()
  }
  func push(_ buffers: UnsafeMutableAudioBufferListPointer, frames: Int) {
    guard !buffers.isEmpty else { return }
    let write = writeIndex.load(ordering: .relaxed)
    let read = readIndex.load(ordering: .acquiring)
    let count = min(frames, max(0, capacity - write + read))
    if count < frames { overruns.add(frames - count, ordering: .relaxed) }
    let first = buffers[0]
    let interleaved = buffers.count == 1 && first.mNumberChannels > 1
    var level: Float = 0
    for frame in 0..<frames {
      for channel in 0..<2 {
        let sample: Float
        if interleaved, let data = first.mData {
          sample =
            data.assumingMemoryBound(to: Float.self)[frame * Int(first.mNumberChannels) + channel]
        } else if let data = buffers[min(channel, buffers.count - 1)].mData {
          sample = data.assumingMemoryBound(to: Float.self)[frame]
        } else {
          sample = 0
        }
        if frame < count { samples[((write + frame) % capacity) * 2 + channel] = sample }
        level = max(level, abs(sample))
      }
    }
    latestLevelBits.store(level.bitPattern, ordering: .relaxed)
    if level > 0.0001 { meaningfulAudioCallbacks.add(1, ordering: .relaxed) }
    captured.add(count, ordering: .relaxed)
    writeIndex.store(write + count, ordering: .releasing)
  }
  func render(_ buffers: UnsafeMutableAudioBufferListPointer, frames: Int) -> Bool {
    for index in 0..<buffers.count {
      if let data = buffers[index].mData {
        memset(data, 0, Int(buffers[index].mDataByteSize))
      }
    }

    var writableFrames = frames
    if buffers.count == 1 {
      let channels = max(1, Int(buffers[0].mNumberChannels))
      guard buffers[0].mData != nil else { return true }
      writableFrames = min(
        writableFrames,
        Int(buffers[0].mDataByteSize) / (channels * MemoryLayout<Float>.size)
      )
    } else {
      let channelCount = min(2, buffers.count)
      guard channelCount > 0 else { return true }
      for channel in 0..<channelCount {
        guard buffers[channel].mData != nil else { return true }
        writableFrames = min(
          writableFrames,
          Int(buffers[channel].mDataByteSize) / MemoryLayout<Float>.size
        )
      }
    }

    let write = writeIndex.load(ordering: .acquiring)
    let read = readIndex.load(ordering: .relaxed)
    let count = min(writableFrames, max(0, write - read))
    if count < writableFrames {
      underruns.add(writableFrames - count, ordering: .relaxed)
    }

    if buffers.count == 1, let data = buffers[0].mData {
      let channels = max(1, Int(buffers[0].mNumberChannels))
      let output = data.assumingMemoryBound(to: Float.self)
      for frame in 0..<count {
        output[frame * channels] = samples[((read + frame) % capacity) * 2]
        if channels > 1 {
          output[frame * channels + 1] = samples[((read + frame) % capacity) * 2 + 1]
        }
      }
    } else {
      for channel in 0..<min(2, buffers.count) {
        guard let data = buffers[channel].mData else { continue }
        let output = data.assumingMemoryBound(to: Float.self)
        for frame in 0..<count {
          output[frame] = samples[((read + frame) % capacity) * 2 + channel]
        }
      }
    }

    readIndex.store(read + count, ordering: .releasing)
    outputFrames.add(writableFrames, ordering: .relaxed)
    return count == 0
  }

  func pop(into buffer: AVAudioPCMBuffer, frames: Int) -> Int {
    let write = writeIndex.load(ordering: .acquiring)
    let read = readIndex.load(ordering: .relaxed)
    let requested = min(frames, Int(buffer.frameCapacity))
    let count = min(requested, max(0, write - read))
    if count < requested {
      underruns.add(requested - count, ordering: .relaxed)
    }
    guard let channels = buffer.floatChannelData else { return 0 }

    for frame in 0..<count {
      channels[0][frame] = samples[((read + frame) % capacity) * 2]
      channels[1][frame] = samples[((read + frame) % capacity) * 2 + 1]
    }

    readIndex.store(read + count, ordering: .releasing)
    return count
  }
}
let routeIOProc: AudioDeviceIOProc = { _, _, input, _, _, _, clientData in
  guard let clientData else { return noErr }
  let buffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
  guard !buffers.isEmpty else { return noErr }
  let frames = floatFrameCount(buffers)
  if frames > 0 {
    Unmanaged<StereoRing>.fromOpaque(clientData).takeUnretainedValue().push(buffers, frames: frames)
  }
  return noErr
}

struct AudioSession {
  let tap: AudioObjectID
  let aggregate: AudioObjectID
  let format: AudioStreamBasicDescription
  var ioProc: AudioDeviceIOProcID?
  init(pid: pid_t, bundleID: String? = nil, name: String) throws {
    let processes = processObjects(for: pid, bundleID: bundleID)
    guard !processes.isEmpty else {
      throw AeroError(description: "cannot find audio process objects for PID \(pid)")
    }
    let tapDescription = CATapDescription(stereoMixdownOfProcesses: processes)
    tapDescription.isPrivate = true
    tapDescription.muteBehavior = .muted
    var tapID = kAudioObjectUnknown
    guard AudioHardwareCreateProcessTap(tapDescription, &tapID) == noErr else {
      throw AeroError(description: "create process tap failed")
    }
    guard
      let output = getScalar(
        AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice,
        default: AudioObjectID(kAudioObjectUnknown)),
      let uid = getString(output, kAudioDevicePropertyDeviceUID)
    else {
      _ = AudioHardwareDestroyProcessTap(tapID)
      throw AeroError(description: "cannot find default output")
    }
    let composition: [String: Any] = [
      kAudioAggregateDeviceNameKey as String: name,
      kAudioAggregateDeviceUIDKey as String: "com.aeroplayd.\(UUID().uuidString)",
      kAudioAggregateDeviceIsPrivateKey as String: true,
      kAudioAggregateDeviceMainSubDeviceKey as String: uid,
      kAudioAggregateDeviceSubDeviceListKey as String: [[kAudioSubDeviceUIDKey as String: uid]],
      kAudioAggregateDeviceTapListKey as String: [
        [
          kAudioSubTapUIDKey as String: tapDescription.uuid.uuidString,
          kAudioSubTapDriftCompensationKey as String: true,
        ]
      ], kAudioAggregateDeviceTapAutoStartKey as String: true,
    ]
    var aggregateID = kAudioObjectUnknown
    guard AudioHardwareCreateAggregateDevice(composition as CFDictionary, &aggregateID) == noErr
    else {
      _ = AudioHardwareDestroyProcessTap(tapID)
      throw AeroError(description: "create aggregate failed")
    }
    var alive = false
    for _ in 0..<100 {
      alive =
        (getScalar(aggregateID, kAudioDevicePropertyDeviceIsAlive, default: UInt32(0)) ?? 0) != 0
      if alive { break }
      usleep(10_000)
    }
    guard alive,
      let format: AudioStreamBasicDescription = getScalar(
        tapID, kAudioTapPropertyFormat, default: AudioStreamBasicDescription())
    else {
      _ = AudioHardwareDestroyAggregateDevice(aggregateID)
      _ = AudioHardwareDestroyProcessTap(tapID)
      throw AeroError(description: "tap did not become alive or has no format")
    }
    let linearPCM =
      (format.mFormatID == kAudioFormatLinearPCM)
      && (format.mFormatFlags & kAudioFormatFlagIsFloat) != 0 && format.mBitsPerChannel == 32
      && format.mChannelsPerFrame == 2
    guard linearPCM else {
      _ = AudioHardwareDestroyAggregateDevice(aggregateID)
      _ = AudioHardwareDestroyProcessTap(tapID)
      throw AeroError(description: "tap format is not stereo Float32 linear PCM")
    }
    self.tap = tapID
    self.aggregate = aggregateID
    self.format = format
  }
}

func stopIOProc(_ session: inout AudioSession) {
  guard let proc = session.ioProc else { return }
  _ = AudioDeviceStop(session.aggregate, proc)
  _ = AudioDeviceDestroyIOProcID(session.aggregate, proc)
  session.ioProc = nil
}

func cleanup(_ session: inout AudioSession) {
  stopIOProc(&session)
  _ = AudioHardwareDestroyAggregateDevice(session.aggregate)
  _ = AudioHardwareDestroyProcessTap(session.tap)
}

func writeWAV(_ recorder: Recorder, _ format: AudioStreamBasicDescription, _ path: String) throws {
  var data = Data()
  var riffSize = UInt32(36 + recorder.frames * recorder.channels * 4)
  var fmtSize: UInt32 = 16
  var tag: UInt16 = 3
  var channels = UInt16(recorder.channels)
  var rate = UInt32(format.mSampleRate)
  var byteRate = rate * UInt32(channels) * 4
  var blockAlign = channels * 4
  var bits: UInt16 = 32
  var dataSize = UInt32(recorder.frames * recorder.channels * 4)
  data.append(contentsOf: Array("RIFF".utf8))
  data.append(Data(bytes: &riffSize, count: 4))
  data.append(contentsOf: Array("WAVEfmt ".utf8))
  data.append(Data(bytes: &fmtSize, count: 4))
  data.append(Data(bytes: &tag, count: 2))
  data.append(Data(bytes: &channels, count: 2))
  data.append(Data(bytes: &rate, count: 4))
  data.append(Data(bytes: &byteRate, count: 4))
  data.append(Data(bytes: &blockAlign, count: 2))
  data.append(Data(bytes: &bits, count: 2))
  data.append(contentsOf: Array("data".utf8))
  data.append(Data(bytes: &dataSize, count: 4))
  data.append(Data(bytes: recorder.samples, count: Int(dataSize)))
  try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

func capture(_ options: Options) throws {
  var session = try AudioSession(pid: options.pid!, name: "capture")
  defer { cleanup(&session) }
  let capacity =
    Int(ceil(options.seconds! * session.format.mSampleRate)) + Int(session.format.mSampleRate)
  let recorder = Recorder(capacity: capacity, channels: 2)
  var proc: AudioDeviceIOProcID?
  guard
    AudioDeviceCreateIOProcID(
      session.aggregate, captureIOProc, Unmanaged.passUnretained(recorder).toOpaque(), &proc)
      == noErr
  else { throw AeroError(description: "create IOProc failed") }
  session.ioProc = proc
  guard AudioDeviceStart(session.aggregate, proc) == noErr else {
    throw AeroError(description: "start device failed")
  }
  print("format: \(session.format.mSampleRate) Hz, 2 channels, float32")
  usleep(useconds_t(options.seconds! * 1_000_000))
  stopIOProc(&session)
  let peak = (0..<(recorder.frames * 2)).reduce(Float(0)) { max($0, abs(recorder.samples[$1])) }
  try writeWAV(recorder, session.format, options.output!)
  print("frames: \(recorder.frames) peak: \(peak) overruns: \(recorder.overruns)")
}

func sourceIsAlive(_ pid: pid_t) -> Bool {
  let result = kill(pid, 0)
  return result == 0 || errno != ESRCH
}

struct HelperProcess {
  let process: Process
  let input: FileHandle
  let volumeFD: Int32
  let controlDirectory: URL
}

func stopHelper(_ helper: HelperProcess) {
  close(helper.volumeFD)
  try? helper.input.close()
  let child = helper.process
  let gracefulDeadline = Date().addingTimeInterval(2)
  while child.isRunning && Date() < gracefulDeadline { usleep(20_000) }
  if child.isRunning {
    child.terminate()
    let terminationDeadline = Date().addingTimeInterval(1)
    while child.isRunning && Date() < terminationDeadline { usleep(20_000) }
  }
  if child.isRunning { _ = kill(child.processIdentifier, SIGKILL) }
  child.waitUntilExit()
  try? FileManager.default.removeItem(at: helper.controlDirectory)
}

func writeNonblocking(
  _ data: Data, to fd: Int32, stop: borrowing Atomic<Bool>, child: Process
) throws -> Bool {
  var deadline = Date().addingTimeInterval(5)
  var offset = 0
  try data.withUnsafeBytes { bytes in
    guard let base = bytes.baseAddress else { return }
    while offset < data.count {
      if stop.load(ordering: .acquiring) { return }
      guard child.isRunning else { throw AeroError(description: "helper exited during route") }
      let count = Darwin.write(fd, base.advanced(by: offset), data.count - offset)
      if count > 0 {
        offset += count
        deadline = Date().addingTimeInterval(5)
        continue
      }
      if errno == EINTR { continue }
      if errno == EAGAIN || errno == EWOULDBLOCK {
        guard Date() < deadline else {
          throw AeroError(description: "helper pipe made no progress")
        }
        usleep(2_000)
        continue
      }
      throw AeroError(description: "helper pipe write failed: \(String(cString: strerror(errno)))")
    }
  }
  return offset == data.count
}

struct RouteMetrics: Sendable {
  let state: String
  let frames: Int
  let sampleRate: Double
  let level: Float
  let peak: Float
  let overruns: Int
  let underruns: Int
}

struct AirPlayPipeline {
  let ring: StereoRing
  let converter: AVAudioConverter
  let inputBuffer: AVAudioPCMBuffer
  let outputBuffer: AVAudioPCMBuffer
  let inputFD: Int32
  let volumeFD: Int32
  let child: Process
}

func writeVolume(_ volume: Int32, to fd: Int32) throws -> Bool {
  var value = UInt8(clamping: volume)
  while true {
    let count = Darwin.write(fd, &value, 1)
    if count == 1 { return true }
    if count < 0 && errno == EINTR { continue }
    if count < 0 && (errno == EAGAIN || errno == EWOULDBLOCK) { return false }
    throw AeroError(description: "helper volume pipe write failed: \(String(cString: strerror(errno)))")
  }
}

func runAirplayLoop(
  _ options: Options, stop: borrowing Atomic<Bool>, pipeline: AirPlayPipeline,
  metrics: ((RouteMetrics) -> Void)?
) throws -> (Int, Float) {
  let ring = pipeline.ring
  let converter = pipeline.converter
  let inputBuffer = pipeline.inputBuffer
  let outputBuffer = pipeline.outputBuffer
  let inputFD = pipeline.inputFD
  let child = pipeline.child
  let deadline = options.seconds.map { Date().addingTimeInterval($0) }
  var sentFrames = 0
  var peak: Float = 0
  var appliedVolume = options.volume
  var lastMetrics = Date.distantPast
  var idleTimer = options.idleAudioTimeoutSeconds.map {
    IdleAudioTimer(
      timeoutSeconds: $0,
      meaningfulAudioCallbacks: ring.meaningfulAudioCallbacks.load(ordering: .relaxed))
  }
  while deadline.map({ Date() < $0 }) ?? true {
    if stop.load(ordering: .acquiring) { break }
    if idleTimer?.hasExpired(
      meaningfulAudioCallbacks: ring.meaningfulAudioCallbacks.load(ordering: .relaxed)) == true {
      stop.store(true, ordering: .releasing)
      break
    }
    let requestedVolume = liveVolumePercent.load(ordering: .relaxed)
    if requestedVolume >= 0, requestedVolume != appliedVolume,
      try writeVolume(requestedVolume, to: pipeline.volumeFD)
    {
      appliedVolume = requestedVolume
    }
    guard sourceIsAlive(options.pid!) else {
      stop.store(true, ordering: .releasing)
      throw AeroError(description: "source process exited")
    }
    guard child.isRunning else {
      throw AeroError(description: "helper exited during route")
    }
    outputBuffer.frameLength = 0
    var conversionError: NSError?
    let status = converter.convert(to: outputBuffer, error: &conversionError) {
      requestedFrames, inputStatus in
      let count = ring.pop(into: inputBuffer, frames: Int(requestedFrames))
      inputBuffer.frameLength = AVAudioFrameCount(count)
      inputStatus.pointee = count == 0 ? .noDataNow : .haveData
      return count == 0 ? nil : inputBuffer
    }
    if status == .error { throw conversionError ?? AeroError(description: "conversion failed") }
    var level: Float = 0
    if outputBuffer.frameLength > 0, let pcm = outputBuffer.int16ChannelData?[0] {
      let sampleCount = Int(outputBuffer.frameLength) * 2
      for index in 0..<sampleCount { level = max(level, abs(Float(pcm[index])) / 32_768) }
      peak = max(peak, level)
      let data = Data(bytes: pcm, count: sampleCount * MemoryLayout<Int16>.size)
      if !(try writeNonblocking(data, to: inputFD, stop: stop, child: child)) { break }
      sentFrames += Int(outputBuffer.frameLength)
    } else {
      usleep(2_000)
    }
    if Date().timeIntervalSince(lastMetrics) >= 0.1 {
      lastMetrics = Date()
      metrics?(
        RouteMetrics(
          state: "Streaming", frames: sentFrames, sampleRate: 44_100, level: level,
          peak: peak, overruns: ring.overruns.load(ordering: .relaxed), underruns: 0))
    }
  }
  return (sentFrames, peak)
}

func spawnHelper(_ options: Options, helper: String) throws -> HelperProcess {
  let pipe = Pipe()
  let controlDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("aeroplayd-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(
    at: controlDirectory, withIntermediateDirectories: false,
    attributes: [.posixPermissions: 0o700])
  let controlURL = controlDirectory.appendingPathComponent("volume")
  guard mkfifo(controlURL.path, mode_t(S_IRUSR | S_IWUSR)) == 0 else {
    try? FileManager.default.removeItem(at: controlDirectory)
    throw AeroError(description: "cannot create helper volume pipe")
  }
  let volumeFD = open(controlURL.path, O_RDWR | O_NONBLOCK | O_CLOEXEC)
  guard volumeFD >= 0 else {
    try? FileManager.default.removeItem(at: controlDirectory)
    throw AeroError(description: "cannot open helper volume pipe")
  }
  let child = Process()
  child.executableURL = URL(fileURLWithPath: helper)
  child.arguments = [
    "-a", "-p", "\(options.port!)", "-v", "\(options.volume)",
    "-c", controlURL.path, "-t", "0,1", "-m", "0,1,2", options.host!, "-",
  ]
  child.standardInput = pipe
  let inputFD = pipe.fileHandleForWriting.fileDescriptor
  let flags = fcntl(inputFD, F_GETFL)
  guard flags >= 0, fcntl(inputFD, F_SETFL, flags | O_NONBLOCK) == 0 else {
    close(volumeFD)
    try? FileManager.default.removeItem(at: controlDirectory)
    throw AeroError(description: "cannot configure helper pipe")
  }
  signal(SIGPIPE, SIG_IGN)
  do { try child.run() } catch {
    close(volumeFD)
    try? FileManager.default.removeItem(at: controlDirectory)
    throw error
  }
  return HelperProcess(
    process: child, input: pipe.fileHandleForWriting, volumeFD: volumeFD,
    controlDirectory: controlDirectory)
}

func routeAirplay(
  _ options: Options, stop: borrowing Atomic<Bool>, metrics: ((RouteMetrics) -> Void)? = nil
) throws {
  guard let helper = options.helper, FileManager.default.isExecutableFile(atPath: helper) else {
    throw AeroError(
      description: "helper is missing or not executable: \(options.helper ?? "(missing)")")
  }

  var session = try AudioSession(pid: options.pid!, bundleID: options.bundleID, name: "route")
  var helperToCleanUp: HelperProcess?
  defer {
    cleanup(&session)
    if let helper = helperToCleanUp { stopHelper(helper) }
  }

  let ringCapacity = max(88_200, Int(session.format.mSampleRate * 2))
  let ring = StereoRing(capacity: ringCapacity)
  var ioProc: AudioDeviceIOProcID?
  guard
    AudioDeviceCreateIOProcID(
      session.aggregate,
      routeIOProc,
      Unmanaged.passUnretained(ring).toOpaque(),
      &ioProc
    ) == noErr
  else {
    throw AeroError(description: "create IOProc failed")
  }
  session.ioProc = ioProc

  guard
    let sourceFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: session.format.mSampleRate,
      channels: 2,
      interleaved: false
    ),
    let destinationFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: 44_100,
      channels: 2,
      interleaved: true
    ),
    let converter = AVAudioConverter(from: sourceFormat, to: destinationFormat),
    let inputBuffer = AVAudioPCMBuffer(
      pcmFormat: sourceFormat,
      frameCapacity: AVAudioFrameCount(ceil(4_096.0 * session.format.mSampleRate / 44_100.0)) + 256
    ),
    let outputBuffer = AVAudioPCMBuffer(
      pcmFormat: destinationFormat,
      frameCapacity: 4_096
    )
  else {
    throw AeroError(description: "converter setup failed")
  }

  guard AudioDeviceStart(session.aggregate, ioProc) == noErr else {
    throw AeroError(description: "start device failed")
  }

  var sentFrames = 0
  var peak: Float = 0
  for attempt in 1...2 {
    var helperOptions = options
    let requestedVolume = liveVolumePercent.load(ordering: .relaxed)
    if requestedVolume >= 0 { helperOptions.volume = requestedVolume }
    let helperProcess = try spawnHelper(helperOptions, helper: helper)
    helperToCleanUp = helperProcess
    guard helperProcess.process.isRunning else {
      throw AeroError(description: "helper exited before capture")
    }
    let pipeline = AirPlayPipeline(
      ring: ring, converter: converter, inputBuffer: inputBuffer, outputBuffer: outputBuffer,
      inputFD: helperProcess.input.fileDescriptor, volumeFD: helperProcess.volumeFD,
      child: helperProcess.process)
    let spawnedAt = Date()
    do {
      (sentFrames, peak) = try runAirplayLoop(
        helperOptions, stop: stop, pipeline: pipeline, metrics: metrics)
      break
    } catch let error as AeroError
      where attempt == 1 && error.description == "helper exited during route"
        && Date().timeIntervalSince(spawnedAt) < 10
        && !stop.load(ordering: .acquiring)
    {
      // Cold AirConnect/Sonos path: the first RTSP connect can time out while
      // the device pipeline wakes. Reap the helper and relaunch it once.
      stopHelper(helperProcess)
      helperToCleanUp = nil
      metrics?(
        RouteMetrics(
          state: "Retrying connection", frames: 0, sampleRate: 44_100, level: 0, peak: 0,
          overruns: ring.overruns.load(ordering: .relaxed), underruns: 0))
      usleep(500_000)
    }
  }

  print(
    "route frames captured: \(ring.captured.load(ordering: .relaxed)) "
      + "sent: \(sentFrames) peak: \(peak) "
      + "overruns: \(ring.overruns.load(ordering: .relaxed))"
  )
}

struct LocalOutputDevice: Identifiable, Hashable {
  let id: AudioObjectID
  let uid: String
  let name: String
  let transport: UInt32
  let nominalRate: Double
  var displayName: String {
    let bluetooth =
      transport == kAudioDeviceTransportTypeBluetooth
      || transport == kAudioDeviceTransportTypeBluetoothLE
    return bluetooth ? "\(name) (Bluetooth)" : name
  }
}

func outputChannelCount(_ device: AudioObjectID) -> Int {
  var address = propertyAddress(
    kAudioDevicePropertyStreamConfiguration, kAudioObjectPropertyScopeOutput)
  var size: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr, size > 0 else {
    return 0
  }
  let storage = UnsafeMutableRawPointer.allocate(
    byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
  defer { storage.deallocate() }
  guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, storage) == noErr else {
    return 0
  }
  let buffers = UnsafeMutableAudioBufferListPointer(
    storage.assumingMemoryBound(to: AudioBufferList.self))
  var channels = 0
  for buffer in buffers {
    channels += Int(buffer.mNumberChannels)
  }
  return channels
}

func localOutputDevices() -> [LocalOutputDevice] {
  let system = AudioObjectID(kAudioObjectSystemObject)
  var address = propertyAddress(kAudioHardwarePropertyDevices)
  var size: UInt32 = 0
  guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
  var ids = [AudioObjectID](
    repeating: kAudioObjectUnknown, count: Int(size) / MemoryLayout<AudioObjectID>.size)
  guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else {
    return []
  }
  return ids.compactMap { id in
    guard (getScalar(id, kAudioDevicePropertyDeviceIsAlive, default: UInt32(0)) ?? 0) != 0,
      let uid = getString(id, kAudioDevicePropertyDeviceUID),
      let name = getString(id, kAudioObjectPropertyName)
    else { return nil }
    var streamAddress = propertyAddress(
      kAudioDevicePropertyStreams, kAudioObjectPropertyScopeOutput)
    var streamSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(id, &streamAddress, 0, nil, &streamSize) == noErr,
      streamSize >= UInt32(MemoryLayout<AudioStreamID>.size), outputChannelCount(id) > 0
    else { return nil }
    let transport = getScalar(id, kAudioDevicePropertyTransportType, default: UInt32(0)) ?? 0
    let rate = getScalar(id, kAudioDevicePropertyNominalSampleRate, default: 0.0) ?? 0
    guard rate > 0 else { return nil }
    return LocalOutputDevice(id: id, uid: uid, name: name, transport: transport, nominalRate: rate)
  }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

func prefillLocal(
  _ options: Options, stop: borrowing Atomic<Bool>, ring: StereoRing, sampleRate: Double,
  configInvalidated: borrowing Atomic<Bool>
) throws {
  let target = max(1, Int(sampleRate * 0.05))
  let deadline = Date().addingTimeInterval(0.25)
  while ring.captured.load(ordering: .acquiring) < target && Date() < deadline {
    if stop.load(ordering: .acquiring) { return }
    if configInvalidated.load(ordering: .acquiring) {
      throw AeroError(description: "audio engine configuration changed")
    }
    guard sourceIsAlive(options.pid!) else { throw AeroError(description: "source process exited") }
    usleep(2_000)
  }
}
func monitorLocal(
  _ options: Options, stop: borrowing Atomic<Bool>, ring: StereoRing, sampleRate: Double,
  uid: String, configInvalidated: borrowing Atomic<Bool>, setVolume: ((Float) -> Void)? = nil,
  metrics: ((RouteMetrics) -> Void)?
) throws -> (Int, Float) {
  var frames = 0
  var peak: Float = 0
  var lastDeviceCheck = Date.distantPast
  let deadline = options.seconds.map { Date().addingTimeInterval($0) }
  var idleTimer = options.idleAudioTimeoutSeconds.map {
    IdleAudioTimer(
      timeoutSeconds: $0,
      meaningfulAudioCallbacks: ring.meaningfulAudioCallbacks.load(ordering: .relaxed))
  }
  while !stop.load(ordering: .acquiring) && deadline.map({ Date() < $0 }) ?? true {
    if idleTimer?.hasExpired(
      meaningfulAudioCallbacks: ring.meaningfulAudioCallbacks.load(ordering: .relaxed)) == true {
      stop.store(true, ordering: .releasing)
      break
    }
    guard sourceIsAlive(options.pid!) else { throw AeroError(description: "source process exited") }
    if configInvalidated.load(ordering: .acquiring) {
      throw AeroError(description: "audio engine configuration changed")
    }
    if Date().timeIntervalSince(lastDeviceCheck) >= 1 {
      lastDeviceCheck = Date()
      guard localOutputDevices().contains(where: { $0.uid == uid }) else {
        throw AeroError(description: "selected output device disappeared")
      }
    }
    frames = ring.outputFrames.load(ordering: .relaxed)
    let liveVolume = liveVolumePercent.load(ordering: .relaxed)
    let effectiveVolume = liveVolume >= 0 ? liveVolume : options.volume
    setVolume?(Float(effectiveVolume) / 100)
    let level =
      Float(bitPattern: ring.latestLevelBits.load(ordering: .relaxed)) * Float(effectiveVolume)
      / 100
    peak = max(peak, level)
    metrics?(
      RouteMetrics(
        state: "Streaming", frames: frames, sampleRate: sampleRate, level: level,
        peak: peak, overruns: ring.overruns.load(ordering: .relaxed),
        underruns: ring.underruns.load(ordering: .relaxed)))
    usleep(100_000)
  }
  return (frames, peak)
}

func localRoute(
  _ options: Options, stop: borrowing Atomic<Bool>, metrics: ((RouteMetrics) -> Void)? = nil
) throws {
  guard let uid = options.deviceUID,
    let device = localOutputDevices().first(where: { $0.uid == uid })
  else {
    throw AeroError(description: "selected output device is unavailable")
  }
  var session = try AudioSession(pid: options.pid!, bundleID: options.bundleID, name: "local-route")
  let ring = StereoRing(capacity: max(88_200, Int(session.format.mSampleRate * 2)))
  var ioProc: AudioDeviceIOProcID?
  guard
    AudioDeviceCreateIOProcID(
      session.aggregate, routeIOProc,
      Unmanaged.passUnretained(ring).toOpaque(), &ioProc) == noErr, let ioProc
  else {
    cleanup(&session)
    throw AeroError(description: "create IOProc failed")
  }
  session.ioProc = ioProc
  guard
    let sourceFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: session.format.mSampleRate, channels: 2, interleaved: false)
  else {
    cleanup(&session)
    throw AeroError(description: "source format setup failed")
  }
  let engine = AVAudioEngine()
  let configInvalidated = Atomic(false)
  var configurationObserver: NSObjectProtocol?
  var attached = false
  let sourceNode = AVAudioSourceNode(format: sourceFormat) {
    isSilence, _, frameCount, audioBufferList in
    let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
    isSilence.pointee = ObjCBool(ring.render(buffers, frames: Int(frameCount)))
    return noErr
  }
  engine.attach(sourceNode)
  attached = true
  defer {
    if let observer = configurationObserver { NotificationCenter.default.removeObserver(observer) }
    engine.stop()
    if attached {
      engine.disconnectNodeOutput(sourceNode)
      engine.detach(sourceNode)
    }
    cleanup(&session)
  }
  guard let outputUnit = engine.outputNode.audioUnit else {
    throw AeroError(description: "selected output has no audio unit")
  }
  var deviceID = device.id
  guard
    AudioUnitSetProperty(
      outputUnit, kAudioOutputUnitProperty_CurrentDevice,
      kAudioUnitScope_Global, 0, &deviceID, UInt32(MemoryLayout<AudioDeviceID>.size)) == noErr
  else {
    throw AeroError(description: "cannot select output device")
  }
  let outputFormat = engine.outputNode.outputFormat(forBus: 0)
  guard outputFormat.sampleRate > 0 else {
    throw AeroError(description: "selected output has no valid format")
  }
  engine.connect(sourceNode, to: engine.mainMixerNode, format: sourceFormat)
  engine.mainMixerNode.outputVolume = Float(options.volume) / 100
  guard AudioDeviceStart(session.aggregate, ioProc) == noErr else {
    throw AeroError(description: "start device failed")
  }
  try prefillLocal(
    options, stop: stop, ring: ring, sampleRate: session.format.mSampleRate,
    configInvalidated: configInvalidated)
  try engine.start()
  configurationObserver = NotificationCenter.default.addObserver(
    forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
  ) { _ in configInvalidated.store(true, ordering: .releasing) }
  // Selecting a non-default device produces one startup configuration notification.
  // Ignore that initial event; later changes stop the route.
  usleep(250_000)
  configInvalidated.store(false, ordering: .releasing)
  let (frames, _) = try monitorLocal(
    options, stop: stop, ring: ring,
    sampleRate: session.format.mSampleRate, uid: uid, configInvalidated: configInvalidated,
    setVolume: { engine.mainMixerNode.outputVolume = $0 },
    metrics: metrics)
  print(
    "local route frames captured: \(ring.captured.load(ordering: .relaxed)) output: \(frames) underruns: \(ring.underruns.load(ordering: .relaxed)) overruns: \(ring.overruns.load(ordering: .relaxed))"
  )
}

func route(
  _ options: Options, stop: borrowing Atomic<Bool>, metrics: ((RouteMetrics) -> Void)? = nil
) throws {
  if options.deviceUID != nil {
    try localRoute(options, stop: stop, metrics: metrics)
  } else {
    try routeAirplay(options, stop: stop, metrics: metrics)
  }
}

@main
struct AeroPlayMain {
  static func main() {
    if CommandLine.arguments.count == 1 {
      MainActor.assumeIsolated { launchUI() }
      return
    }
    let options = parseOptions()
    do {
      switch options.mode {
      case .list: listApps()
      case .capture: try capture(options)
      case .route:
        let stop = Atomic(false)
        try route(options, stop: stop)
      }
    } catch { fail(String(describing: error)) }
  }
}
