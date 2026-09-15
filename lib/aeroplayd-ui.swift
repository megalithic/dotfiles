import AVFoundation
import AppKit
import Combine
import CoreAudio
import Foundation
import SwiftUI
import Synchronization

final class DestinationBrowser: NSObject, ObservableObject, NetServiceBrowserDelegate,
  NetServiceDelegate
{
  struct Destination: Identifiable, Hashable {
    let id: String
    let displayName: String
    let service: NetService?
    var host: String?
    var port: Int32 = 0
    var txt: [String: String] = [:]
    let deviceUID: String?
    let deviceID: AudioObjectID?
    static func == (lhs: Destination, rhs: Destination) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
  }
  @Published var destinations: [Destination] = []
  var onRemoval: ((String) -> Void)?
  private let browser = NetServiceBrowser()
  private var services: [String: NetService] = [:]
  private var deviceListener: AudioObjectPropertyListenerBlock?
  override init() {
    super.init()
    browser.delegate = self
    browser.searchForServices(ofType: "_raop._tcp.", inDomain: "local.")
    refreshLocalDevices()
    let system = AudioObjectID(kAudioObjectSystemObject)
    var address = propertyAddress(kAudioHardwarePropertyDevices)
    let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
      DispatchQueue.main.async { self?.refreshLocalDevices() }
    }
    deviceListener = listener
    _ = AudioObjectAddPropertyListenerBlock(system, &address, DispatchQueue.main, listener)
  }
  deinit {
    browser.stop()
    if let listener = deviceListener {
      var address = propertyAddress(kAudioHardwarePropertyDevices)
      _ = AudioObjectRemovePropertyListenerBlock(
        AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main, listener)
    }
  }
  func refreshLocalDevices() {
    dispatchPrecondition(condition: .onQueue(.main))
    let previousIDs = Set(
      destinations.lazy.filter { $0.id.hasPrefix("coreaudio:") }.map(\.id))
    let local = localOutputDevices()
    let localDestinations = local.map { device in
      Destination(
        id: "coreaudio:\(device.uid)", displayName: device.displayName, service: nil,
        host: nil, port: 0, txt: [:], deviceUID: device.uid, deviceID: device.id)
    }
    let currentIDs = Set(localDestinations.map(\.id))
    let remote = destinations.filter { !$0.id.hasPrefix("coreaudio:") }
    destinations = remote + localDestinations
    for removedID in previousIDs.subtracting(currentIDs) {
      onRemoval?(removedID)
    }
  }
  func netServiceBrowser(
    _ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool
  ) {
    DispatchQueue.main.async { [weak self] in self?.handleFound(service) }
  }
  private func handleFound(_ service: NetService) {
    dispatchPrecondition(condition: .onQueue(.main))
    let id = "raop:\(service.name)|\(service.type)|\(service.domain)"
    services[id]?.stop()
    services[id] = service
    destinations.removeAll { $0.id == id }
    service.delegate = self
    service.resolve(withTimeout: 5)
  }
  func netServiceDidResolveAddress(_ sender: NetService) {
    DispatchQueue.main.async { [weak self] in self?.handleResolved(sender) }
  }
  private func handleResolved(_ sender: NetService) {
    dispatchPrecondition(condition: .onQueue(.main))
    let id = "raop:\(sender.name)|\(sender.type)|\(sender.domain)"
    guard services[id] === sender else { return }
    let txt =
      NetService.dictionary(fromTXTRecord: sender.txtRecordData() ?? Data())
      .reduce(into: [String: String]()) {
        $0[$1.key] = String(data: $1.value, encoding: .utf8) ?? ""
      }
    let previous = destinations.first { $0.id == id && $0.service === sender }
    let host = sender.hostName ?? previous?.host
    let port = sender.port > 0 ? Int32(sender.port) : (previous?.port ?? 0)
    guard host != nil, port > 0 else { return }
    let destination = Destination(
      id: id,
      displayName: sender.name.split(separator: "@", maxSplits: 1).last.map(String.init)
        ?? sender.name, service: sender, host: host, port: port, txt: txt,
      deviceUID: nil, deviceID: nil)
    destinations.removeAll { $0.id == id }
    destinations.append(destination)
  }
  func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
    netServiceDidResolveAddress(sender)
  }
  func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    DispatchQueue.main.async { [weak self] in self?.handleFailure(sender) }
  }
  private func handleFailure(_ sender: NetService) {
    dispatchPrecondition(condition: .onQueue(.main))
    let id = "raop:\(sender.name)|\(sender.type)|\(sender.domain)"
    guard services[id] === sender else { return }
    services[id] = nil
    destinations.removeAll { $0.id == id }
    onRemoval?(id)
  }
  func netServiceBrowser(
    _ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool
  ) {
    DispatchQueue.main.async { [weak self] in self?.handleRemoved(service) }
  }
  private func handleRemoved(_ service: NetService) {
    dispatchPrecondition(condition: .onQueue(.main))
    let id = "raop:\(service.name)|\(service.type)|\(service.domain)"
    guard services[id] === service else { return }
    services[id] = nil
    destinations.removeAll { $0.id == id }
    onRemoval?(id)
  }
}

struct RunningApp: Identifiable, Hashable {
  let id: pid_t
  let name: String
  let bundleID: String
}

@MainActor final class AeroController: ObservableObject {
  @Published var apps: [RunningApp] = []
  @Published var destinations: [DestinationBrowser.Destination] = []
  @Published var selectedApp: RunningApp?
  @Published var selectedDestinationID: String?
  @Published var volume: Double = 15 {
    didSet { liveVolumePercent.store(Int32(volume), ordering: .relaxed) }
  }
  @Published var status = "Idle"
  @Published var metrics = ""
  @Published var level: Double = 0
  @Published private(set) var sourceIconVisible = false
  @Published private(set) var isRouting = false
  @Published private(set) var isStopping = false
  let browser = DestinationBrowser()
  private let stop = Atomic(false)
  private var worker: Task<Void, Never>?
  private var terminationCompletion: (() -> Void)?
  private var generation = 0
  private var browserObservation: AnyCancellable?

  init() {
    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
    ) { [weak self] _ in Task { @MainActor in self?.refreshApps() } }
    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
    ) { [weak self] _ in Task { @MainActor in self?.refreshApps() } }
    browserObservation = browser.$destinations
      .receive(on: DispatchQueue.main)
      .sink { [weak self] destinations in self?.destinations = destinations }
    destinations = browser.destinations
    browser.onRemoval = { [weak self] id in
      guard let self, self.selectedDestinationID == id else { return }
      self.selectedDestinationID = nil
      if self.isRouting {
        self.stopRoute()
      } else {
        self.status = "Destination unavailable"
      }
    }
    refreshApps()
  }
  func refreshApps() {
    apps = NSWorkspace.shared.runningApplications.filter {
      $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier
    }.compactMap { app in
      guard let bundle = app.bundleIdentifier else { return nil }
      return RunningApp(
        id: app.processIdentifier, name: app.localizedName ?? bundle, bundleID: bundle)
    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    if let selected = selectedApp,
      !apps.contains(where: { $0.id == selected.id && $0.bundleID == selected.bundleID })
    {
      selectedApp = nil
    }
  }
  func selectedDestination() -> DestinationBrowser.Destination? {
    guard let id = selectedDestinationID else { return nil }
    return browser.destinations.first { $0.id == id }
  }
  func start() {
    guard !isRouting, !isStopping, let app = selectedApp,
      let running = NSRunningApplication(processIdentifier: app.id),
      !running.isTerminated, running.bundleIdentifier == app.bundleID,
      let destination = selectedDestination()
    else {
      status = "Error: select source and destination"
      return
    }
    let local = destination.deviceUID != nil
    guard local || (destination.host != nil && destination.port > 0) else {
      status = "Error: destination is unavailable"
      return
    }
    guard local || helperURL() != nil else {
      status = "Error: bundled cliraop is absent"
      return
    }
    stop.store(false, ordering: .releasing)
    generation += 1
    let routeGeneration = generation
    let idleAudioTimeoutSeconds = loadIdleAudioTimeoutSeconds()
    let options = Options(
      mode: .route, pid: app.id, seconds: nil, output: nil, host: destination.host,
      port: destination.port, helper: helperURL()?.path, deviceUID: destination.deviceUID,
      volume: Int32(volume), bundleID: app.bundleID,
      idleAudioTimeoutSeconds: idleAudioTimeoutSeconds)
    isRouting = true
    isStopping = false
    sourceIconVisible = true
    status = "Connecting"
    worker = Task.detached { [weak self] in
      guard let self else { return }
      do {
        try route(options, stop: self.stop) { [weak self] value in
          Task { @MainActor in
            guard let self, self.generation == routeGeneration, self.isRouting else { return }
            self.level = Double(value.level)
            self.status = value.state
            let seconds = Double(value.frames) / value.sampleRate
            self.metrics = String(
              format: "%.1fs sent  peak %.2f  overruns %d  underruns %d", seconds, value.peak,
              value.overruns, value.underruns)
          }
        }
        await MainActor.run { [weak self] in
          self?.finishRoute(error: nil, generation: routeGeneration)
        }
      } catch {
        await MainActor.run { [weak self] in
          self?.finishRoute(error: error, generation: routeGeneration)
        }
      }
    }
  }
  func stopRoute() {
    guard isRouting else { return }
    isStopping = true
    status = "Stopping"
    stop.store(true, ordering: .releasing)
  }
  func stopRouteForTermination(completion: @escaping () -> Void) {
    guard isRouting else {
      completion()
      return
    }
    terminationCompletion = completion
    stopRoute()
  }
  func finishRoute(error: Error?, generation routeGeneration: Int) {
    guard generation == routeGeneration else { return }
    worker = nil
    isRouting = false
    isStopping = false
    level = 0
    sourceIconVisible = false
    if let error { status = "Error: \(error)" } else { status = "Idle" }
    let completion = terminationCompletion
    terminationCompletion = nil
    completion?()
  }
  func helperURL() -> URL? {
    guard let resource = Bundle.main.resourceURL else { return nil }
    let helper = resource.appendingPathComponent("cliraop")
    return FileManager.default.isExecutableFile(atPath: helper.path) ? helper : nil
  }
}

struct AeroPopover: View {
  @StateObject var controller: AeroController

  private var officeDestination: DestinationBrowser.Destination? {
    controller.destinations.first {
      $0.displayName == "Office+" && $0.host != nil && $0.port > 0
    }
  }

  private func runningApp(bundleID: String) -> RunningApp? {
    controller.apps.first { $0.bundleID == bundleID }
  }

  private func appIcon(bundleID: String) -> NSImage {
    if let app = runningApp(bundleID: bundleID),
      let icon = NSRunningApplication(processIdentifier: app.id)?.icon
    {
      return icon
    }
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
      return NSWorkspace.shared.icon(forFile: url.path)
    }
    return NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
  }

  private func quickRoute(bundleID: String) {
    guard let app = runningApp(bundleID: bundleID), let destination = officeDestination else {
      return
    }
    controller.selectedApp = app
    controller.selectedDestinationID = destination.id
    controller.start()
  }

  private func quickRouteButton(name: String, bundleID: String) -> some View {
    Button { quickRoute(bundleID: bundleID) } label: {
      HStack(spacing: 5) {
        Image(nsImage: appIcon(bundleID: bundleID))
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
          .accessibilityHidden(true)
        Text("\(name) → Office+").lineLimit(1)
      }.frame(maxWidth: .infinity)
    }
    .controlSize(.small)
    .disabled(
      controller.isRouting || controller.isStopping || runningApp(bundleID: bundleID) == nil
        || officeDestination == nil)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("AeroPlay").font(.headline)
      HStack {
        Text("Source").frame(width: 84, alignment: .leading)
        Picker("Source", selection: $controller.selectedApp) {
          Text("Select source").tag(nil as RunningApp?)
          ForEach(controller.apps) { Text($0.name).tag(Optional($0)) }
        }.pickerStyle(.menu).labelsHidden()
          .frame(maxWidth: .infinity, alignment: .leading)
          .disabled(controller.isRouting || controller.isStopping)
      }
      HStack {
        Text("Destination").frame(width: 84, alignment: .leading)
        Picker("Destination", selection: $controller.selectedDestinationID) {
          Text("Select destination").tag(nil as String?)
          ForEach(controller.destinations) { Text($0.displayName).tag(Optional($0.id)) }
        }.pickerStyle(.menu).labelsHidden()
          .frame(maxWidth: .infinity, alignment: .leading)
          .disabled(controller.isRouting || controller.isStopping)
      }
      HStack(spacing: 8) {
        quickRouteButton(name: "Kaset", bundleID: "com.sertacozercan.Kaset")
        quickRouteButton(name: "Helium", bundleID: "net.imput.helium")
      }
      Text("Status: \(controller.status)")
      Text(controller.metrics).font(.caption).monospaced()
      ProgressView(value: min(1, sqrt(max(0, controller.level))), total: 1).tint(.accentColor)
      HStack {
        Text("Volume \(Int(controller.volume))")
        Slider(value: $controller.volume, in: 0...100)
      }
      HStack {
        Button("Start") { controller.start() }.disabled(
          controller.isRouting || controller.isStopping)
        Button("Stop") { controller.stopRoute() }.disabled(
          !controller.isRouting || controller.isStopping)
        Button("Quit") { NSApp.terminate(nil) }
      }
    }.onAppear {
      controller.refreshApps()
      controller.browser.refreshLocalDevices()
    }
    .onChange(of: controller.isRouting) { _, active in if !active { controller.refreshApps() } }
    .padding().frame(width: 320)
  }
}

@MainActor final class StatusDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  let popover = NSPopover()
  let controller = AeroController()
  private var sigtermSource: DispatchSourceSignal?
  private var sigintSource: DispatchSourceSignal?
  private var clickMonitor: Any?
  private var popoverGeneration = 0
  private var iconObservation: AnyCancellable?
  func applicationDidFinishLaunching(_ notification: Notification) {
    signal(SIGTERM, SIG_IGN)
    signal(SIGINT, SIG_IGN)
    sigtermSource = signalSource(SIGTERM)
    sigintSource = signalSource(SIGINT)
    updateStatusIcon(visible: false)
    popover.behavior = .transient
    popover.delegate = self
    popover.contentViewController = NSHostingController(
      rootView: AeroPopover(controller: self.controller))
    iconObservation = controller.$sourceIconVisible
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] visible in self?.updateStatusIcon(visible: visible) }
    item.button?.action = #selector(toggle)
    item.button?.target = self
  }
  private func signalSource(_ value: Int32) -> DispatchSourceSignal {
    let source = DispatchSource.makeSignalSource(signal: value, queue: .main)
    source.setEventHandler { NSApp.terminate(nil) }
    source.resume()
    return source
  }
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard controller.isRouting else { return .terminateNow }
    controller.stopRouteForTermination {
      NSApp.reply(toApplicationShouldTerminate: true)
    }
    return .terminateLater
  }
  func applicationWillTerminate(_ notification: Notification) {
    closePopover()
    controller.stopRoute()
    updateStatusIcon(visible: false)
  }
  func applicationDidResignActive(_ notification: Notification) { closePopover() }
  private func updateStatusIcon(visible: Bool) {
    guard let button = item.button,
      let airPlayIcon = NSImage(
        systemSymbolName: "airplayaudio", accessibilityDescription: "AeroPlay")
    else { return }
    button.imageScaling = .scaleProportionallyDown
    if visible, let app = controller.selectedApp,
      let appIcon = NSRunningApplication(processIdentifier: app.id)?.icon
    {
      let iconSize: CGFloat = 18
      let spacing: CGFloat = 3
      let size = NSSize(width: iconSize * 2 + spacing, height: iconSize)
      let symbol = airPlayIcon.withSymbolConfiguration(
        NSImage.SymbolConfiguration(paletteColors: [.labelColor])) ?? airPlayIcon
      button.image = NSImage(size: size, flipped: false) { _ in
        appIcon.draw(
          in: NSRect(x: 0, y: 0, width: iconSize, height: iconSize),
          from: .zero, operation: .sourceOver, fraction: 1)
        symbol.draw(
          in: NSRect(x: iconSize + spacing, y: 0, width: iconSize, height: iconSize),
          from: .zero, operation: .sourceOver, fraction: 1)
        return true
      }
      button.toolTip = "AeroPlay is streaming \(app.name)"
      button.setAccessibilityLabel("AeroPlay streaming \(app.name)")
    } else {
      airPlayIcon.isTemplate = true
      button.image = airPlayIcon
      button.toolTip = "AeroPlay"
      button.setAccessibilityLabel("AeroPlay")
    }
  }
  func popoverDidClose(_ notification: Notification) { removeClickMonitor() }
  private func closePopover() {
    if popover.isShown {
      popoverGeneration += 1
      popover.performClose(nil)
    }
    removeClickMonitor()
  }
  private func removeClickMonitor() {
    if let monitor = clickMonitor {
      NSEvent.removeMonitor(monitor)
      clickMonitor = nil
    }
  }
  @objc func toggle() {
    if popover.isShown {
      closePopover()
    } else if let button = item.button {
      controller.refreshApps()
      controller.browser.refreshLocalDevices()
      removeClickMonitor()
      NSApp.activate()
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popoverGeneration += 1
      let generation = popoverGeneration
      // Transient popovers from accessory apps miss outside clicks in other
      // apps; a global monitor closes the popover without eating the click.
      clickMonitor = NSEvent.addGlobalMonitorForEvents(
        matching: [.leftMouseDown, .rightMouseDown]
      ) { [weak self] _ in
        Task { @MainActor in
          guard self?.popoverGeneration == generation else { return }
          self?.closePopover()
        }
      }
    }
  }
}

@MainActor func launchUI() {
  let app = NSApplication.shared
  let delegate = StatusDelegate()
  app.delegate = delegate
  app.setActivationPolicy(.accessory)
  app.run()
}
