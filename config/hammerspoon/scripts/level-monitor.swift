#!/usr/bin/swift
// level-monitor.swift - Monitor microphone input levels via AVAudioEngine
//
// Usage:
//   level-monitor.swift              # Continuous monitoring (legacy)
//   level-monitor.swift --once       # Single reading
//   level-monitor.swift --interactive # Command mode: "start"/"stop" via stdin
//
// Interactive mode pre-warms the engine without activating the mic.
// Send "start" to begin monitoring, "stop" to pause. Mic indicator only
// appears while actively monitoring.

import AVFoundation
import Foundation

class AudioLevelMonitor {
    private let engine = AVAudioEngine()
    private var isMonitoring = false
    private var lastLevel: Float = 0.0
    private let smoothing: Float = 0.3
    private var levelCallback: ((Float) -> Void)?
    
    init?() {
        if #available(macOS 10.14, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            if status == .notDetermined {
                let semaphore = DispatchSemaphore(value: 0)
                AVCaptureDevice.requestAccess(for: .audio) { _ in semaphore.signal() }
                semaphore.wait()
            }
            if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
                fputs("error: mic access denied\n", stderr)
                return nil
            }
        }
    }
    
    func prepare() {
        // Access inputNode to trigger lazy initialization
        _ = engine.inputNode.outputFormat(forBus: 0)
        engine.prepare()
    }
    
    private func calculateRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameLength {
                let sample = data[frame]
                sum += sample * sample
            }
        }
        return sqrt(sum / Float(frameLength * channelCount))
    }
    
    private func normalizeLevel(_ rms: Float) -> Float {
        guard rms > 0.00001 else { return 0.0 }
        let db = 20.0 * log10(rms)
        let normalized = (db - (-60.0)) / (0.0 - (-60.0))
        return max(0.0, min(1.0, normalized))
    }
    
    func startMonitoring(onLevel: @escaping (Float) -> Void) -> Bool {
        if isMonitoring { return true }
        
        levelCallback = onLevel
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let rms = self.calculateRMS(buffer)
            let level = self.normalizeLevel(rms)
            let smoothed = self.lastLevel * self.smoothing + level * (1.0 - self.smoothing)
            self.lastLevel = smoothed
            self.levelCallback?(smoothed)
        }
        
        do {
            try engine.start()
            isMonitoring = true
            return true
        } catch {
            fputs("error: \(error)\n", stderr)
            inputNode.removeTap(onBus: 0)
            return false
        }
    }
    
    func stopMonitoring() {
        if !isMonitoring { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        isMonitoring = false
        lastLevel = 0.0
    }
    
    func runContinuous() {
        var lastOutputTime = Date()
        guard startMonitoring(onLevel: { level in
            let now = Date()
            if now.timeIntervalSince(lastOutputTime) >= 0.05 {
                print(String(format: "%.3f", level))
                fflush(stdout)
                lastOutputTime = now
            }
        }) else { exit(1) }
        
        signal(SIGINT) { _ in exit(0) }
        signal(SIGTERM) { _ in exit(0) }
        RunLoop.current.run()
    }
    
    func runInteractive() {
        prepare()
        print("ready")
        fflush(stdout)
        
        var lastOutputTime = Date()
        let outputCallback: (Float) -> Void = { level in
            let now = Date()
            if now.timeIntervalSince(lastOutputTime) >= 0.05 {
                print(String(format: "%.3f", level))
                fflush(stdout)
                lastOutputTime = now
            }
        }
        
        // Read commands from stdin on a background queue
        let stdinQueue = DispatchQueue(label: "stdin")
        stdinQueue.async {
            while let line = readLine() {
                let cmd = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                DispatchQueue.main.async {
                    switch cmd {
                    case "start":
                        if self.startMonitoring(onLevel: outputCallback) {
                            print("started")
                            fflush(stdout)
                        }
                    case "stop":
                        self.stopMonitoring()
                        print("stopped")
                        fflush(stdout)
                    case "quit", "exit":
                        self.stopMonitoring()
                        exit(0)
                    default:
                        break
                    }
                }
            }
            // stdin closed
            DispatchQueue.main.async { exit(0) }
        }
        
        signal(SIGINT) { _ in exit(0) }
        signal(SIGTERM) { _ in exit(0) }
        RunLoop.current.run()
    }
    
    func readOnce() -> Float? {
        var result: Float?
        let semaphore = DispatchSemaphore(value: 0)
        
        guard startMonitoring(onLevel: { level in
            if result == nil {
                result = level
                semaphore.signal()
            }
        }) else { return nil }
        
        if semaphore.wait(timeout: .now() + .milliseconds(500)) == .timedOut {
            stopMonitoring()
            return 0.0
        }
        stopMonitoring()
        return result
    }
}

// Main
guard let monitor = AudioLevelMonitor() else { exit(1) }

let args = CommandLine.arguments
if args.contains("--once") {
    if let level = monitor.readOnce() {
        print(String(format: "%.3f", level))
    } else {
        print("0.000")
    }
} else if args.contains("--interactive") {
    monitor.runInteractive()
} else {
    monitor.runContinuous()
}
